use axum::{extract::State, middleware, routing::get, Json, Router};
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
use std::time::Duration;
use supabase_jwt::JwksCache;

pub mod auth;
pub mod users;

#[derive(Clone)]
pub struct AppState {
    pub db: Option<PgPool>,
    pub jwks: JwksCache,
}

pub async fn init_db_pool() -> Option<PgPool> {
    let url = match std::env::var("DATABASE_URL") {
        Ok(v) if !v.is_empty() => v,
        _ => {
            tracing::warn!("DATABASE_URL not set — starting without a database pool");
            return None;
        }
    };

    let pool = match PgPoolOptions::new()
        .max_connections(5)
        .min_connections(1)
        // Recycle connections faster than the Supabase Supavisor pooler's
        // idle-close window so sqlx detects dead sockets and rotates proactively.
        .idle_timeout(Duration::from_secs(30))
        .acquire_timeout(Duration::from_secs(3))
        .test_before_acquire(true)
        .connect_lazy(&url)
    {
        Ok(p) => p,
        Err(e) => {
            tracing::error!("failed to build sqlx pool: {e}");
            return None;
        }
    };

    // Warm the pool: the first connection across regions to a Supabase Supavisor
    // pooler takes ~1–3s (TLS + SCRAM auth + handshake). Doing it at startup
    // keeps /health snappy (<100ms) for every subsequent request.
    match tokio::time::timeout(
        Duration::from_secs(10),
        sqlx::query("SELECT 1").execute(&pool),
    )
    .await
    {
        Ok(Ok(_)) => tracing::info!("DATABASE_URL detected — sqlx pool warm"),
        Ok(Err(e)) => tracing::warn!(
            "sqlx pool warm-up failed (non-fatal, server still starting): {e}"
        ),
        Err(_) => tracing::warn!(
            "sqlx pool warm-up timed out after 10s (non-fatal, server still starting)"
        ),
    }

    Some(pool)
}

/// Build the JwksCache from `SUPABASE_URL`. Returns a non-functional cache
/// pointing at `https://invalid.local/jwks` if the env var is missing — that
/// keeps the server bootable for local tests of the public routes without
/// having to set Supabase env. Real verification still requires SUPABASE_URL.
pub fn init_jwks_cache() -> JwksCache {
    let supabase_url = std::env::var("SUPABASE_URL").unwrap_or_else(|_| {
        tracing::warn!(
            "SUPABASE_URL not set — auth middleware will reject all tokens"
        );
        "https://invalid.local".to_string()
    });
    let jwks_url = auth::jwks_url_from_supabase_url(&supabase_url);
    tracing::info!("JWKS endpoint: {jwks_url}");
    JwksCache::new(&jwks_url)
}

pub fn app(state: AppState) -> Router {
    // Routes that require a valid Supabase JWT.
    let protected = Router::new()
        .route("/users/me", get(users::get_or_bootstrap_me))
        .layer(middleware::from_fn_with_state(
            state.jwks.clone(),
            auth::require_auth,
        ));

    Router::new()
        .route("/health", get(health))
        .merge(protected)
        .with_state(state)
}

#[derive(serde::Serialize, utoipa::ToSchema)]
pub struct HealthResponse {
    status: &'static str,
    db: &'static str,
}

#[utoipa::path(
    get,
    path = "/health",
    responses(
        (status = 200, description = "Service health + DB readiness", body = HealthResponse)
    ),
    tag = "system"
)]
pub async fn health(State(state): State<AppState>) -> Json<HealthResponse> {
    let db_status: &'static str = match &state.db {
        None => "unconfigured",
        Some(pool) => {
            // Pool is pre-warmed at startup; test_before_acquire(true) means
            // sqlx pings the connection before handoff. Cross-region (e.g.
            // KR ↔ ap-south-1) makes 500ms tight under jitter — 1.5s is a
            // realistic upper bound for a healthy SELECT 1 plus the ping.
            match tokio::time::timeout(
                Duration::from_millis(1500),
                sqlx::query("SELECT 1").execute(pool),
            )
            .await
            {
                Ok(Ok(_)) => "connected",
                _ => "disconnected",
            }
        }
    };
    Json(HealthResponse {
        status: "ok",
        db: db_status,
    })
}

#[derive(utoipa::OpenApi)]
#[openapi(
    paths(health, users::get_or_bootstrap_me),
    components(schemas(HealthResponse, users::UserProfile)),
    info(
        title = "ITER API",
        version = "0.1.0",
        description = "ITER MVP backend API. Source: srs/03-api.md."
    ),
    tags(
        (name = "system", description = "Health and operational endpoints"),
        (name = "users", description = "User profile endpoints")
    )
)]
pub struct ApiDoc;
