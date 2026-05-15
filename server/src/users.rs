// F1.3 — User profile bootstrap.
//
// `GET /users/me` looks up the caller's profile row by `id = JWT.sub`. On
// first call (no row exists yet), bootstraps a default profile and returns
// it. Subsequent calls just SELECT.
//
// The `users` table is the application's profile store. `users.id` is the
// same UUID as `auth.uid()` — see ADR-002 + the migration comments. There
// is no separate `auth_user_id` linkage column.

use axum::{extract::State, http::StatusCode, Extension, Json};
use chrono::{DateTime, Utc};
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::AppState;

#[derive(serde::Serialize, sqlx::FromRow, utoipa::ToSchema, Debug)]
pub struct UserProfile {
    #[schema(value_type = String, format = "uuid")]
    pub id: Uuid,
    pub username: String,
    pub email: Option<String>,
    pub profile_photo_url: Option<String>,
    pub bio: Option<String>,
    #[schema(value_type = String, format = "date-time")]
    pub created_at: DateTime<Utc>,
    #[schema(value_type = String, format = "date-time")]
    pub updated_at: DateTime<Utc>,
}

#[utoipa::path(
    get,
    path = "/users/me",
    responses(
        (status = 200, description = "Current user's profile (created on first call)", body = UserProfile),
        (status = 401, description = "Missing or invalid Bearer token"),
        (status = 503, description = "Database is unconfigured or unreachable")
    ),
    security(("bearerAuth" = [])),
    tag = "users"
)]
pub async fn get_or_bootstrap_me(
    State(state): State<AppState>,
    Extension(user): Extension<AuthUser>,
) -> Result<Json<UserProfile>, StatusCode> {
    let db = state
        .db
        .as_ref()
        .ok_or(StatusCode::SERVICE_UNAVAILABLE)?;

    let auth_uid = Uuid::parse_str(&user.user_id).map_err(|e| {
        tracing::warn!("JWT sub is not a UUID: {e}");
        StatusCode::UNAUTHORIZED
    })?;

    // Fast path: profile already exists.
    let existing: Option<UserProfile> = sqlx::query_as(
        "SELECT id, username, email, profile_photo_url, bio, created_at, updated_at \
         FROM users WHERE id = $1",
    )
    .bind(auth_uid)
    .fetch_optional(db)
    .await
    .map_err(|e| {
        tracing::error!("/users/me SELECT failed: {e}");
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    if let Some(profile) = existing {
        return Ok(Json(profile));
    }

    // Bootstrap: generate a default username from the auth UUID. 8 hex chars
    // gives ~4B unique values — collision odds negligible for the MVP. Users
    // can update their username later via a (future) profile-edit endpoint.
    let default_username = format!("user_{}", &auth_uid.simple().to_string()[..8]);

    let inserted: UserProfile = sqlx::query_as(
        "INSERT INTO users (id, username, email) \
         VALUES ($1, $2, $3) \
         RETURNING id, username, email, profile_photo_url, bio, created_at, updated_at",
    )
    .bind(auth_uid)
    .bind(&default_username)
    .bind(user.email.as_deref())
    .fetch_one(db)
    .await
    .map_err(|e| {
        tracing::error!("/users/me bootstrap INSERT failed: {e}");
        StatusCode::INTERNAL_SERVER_ERROR
    })?;

    tracing::info!(
        user_id = %inserted.id,
        username = %inserted.username,
        "bootstrapped new user profile"
    );

    Ok(Json(inserted))
}
