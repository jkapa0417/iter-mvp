use std::env;
use tokio::net::TcpListener;
use tracing_subscriber::EnvFilter;
use utoipa::OpenApi;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Check --emit-openapi BEFORE tracing init so stdout stays clean.
    if env::args().any(|a| a == "--emit-openapi") {
        let json = iter_server::ApiDoc::openapi().to_pretty_json()?;
        println!("{json}");
        return Ok(());
    }

    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .with_writer(std::io::stderr)
        .init();

    let port = env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let addr = format!("0.0.0.0:{port}");

    let state = iter_server::AppState {
        db: iter_server::init_db_pool().await,
        jwks: iter_server::init_jwks_cache(),
    };

    let listener = TcpListener::bind(&addr).await?;
    tracing::info!("iter-server listening on {addr}");
    axum::serve(listener, iter_server::app(state)).await?;
    Ok(())
}
