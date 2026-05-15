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

    match PgPoolOptions::new()
        .max_connections(5)
        .acquire_timeout(Duration::from_secs(3))
        .connect_lazy(&url)
    {
        Ok(pool) => {
            tracing::info!("DATABASE_URL detected — sqlx pool created (lazy)");
            Some(pool)
        }
        Err(e) => {
            tracing::error!("failed to build sqlx pool: {e}");
            None
        }
    }
}

pub fn app(state: AppState) -> Router {
    Router::new()
        .route("/health", get(health))
        .with_state(state)
}

#[derive(serde::Serialize)]
struct HealthResponse {
    status: &'static str,
    db: &'static str,
}

async fn health(State(state): State<AppState>) -> Json<HealthResponse> {
    let db_status: &'static str = match &state.db {
        None => "unconfigured",
        Some(pool) => {
            match tokio::time::timeout(
                Duration::from_millis(500),
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
