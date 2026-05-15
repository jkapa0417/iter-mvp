use axum::{extract::State, routing::get, Json, Router};
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
use std::time::Duration;

#[derive(Clone)]
pub struct AppState {
    pub db: Option<PgPool>,
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

pub fn app(state: AppState) -> Router {
    Router::new()
        .route("/health", get(health))
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
    paths(health),
    components(schemas(HealthResponse)),
    info(
        title = "ITER API",
        version = "0.1.0",
        description = "ITER MVP backend API. Source: srs/03-api.md."
    ),
    tags(
        (name = "system", description = "Health and operational endpoints")
    )
)]
pub struct ApiDoc;
