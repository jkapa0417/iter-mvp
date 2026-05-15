use axum::{routing::get, Router};

async fn health() -> &'static str {
    "ok"
}

pub fn app() -> Router {
    Router::new().route("/health", get(health))
}
