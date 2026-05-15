// F1.2 — Auth middleware unit tests.
//
// Negative cases only: missing header, malformed header, garbage token. The
// happy path (valid Supabase-issued JWT) requires a live JWKS endpoint or a
// mocked one with a matching signing key — out of scope for CI (verified
// end-to-end via the Flutter app against a real Supabase instance instead).

use axum::body::Body;
use axum::http::{Request, StatusCode};
use tower::ServiceExt;

fn build_app() -> axum::Router {
    let state = iter_server::AppState {
        db: None,
        // Points to an unreachable host — sufficient because all assertions
        // here fail BEFORE the JWKS is consulted (header missing / unparsable
        // / token malformed).
        jwks: supabase_jwt::JwksCache::new("https://invalid.local/jwks"),
    };
    iter_server::app(state)
}

#[tokio::test]
async fn me_without_header_returns_401() {
    let app = build_app();
    let response = app
        .oneshot(Request::builder().uri("/users/me").body(Body::empty()).unwrap())
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn me_with_non_bearer_header_returns_401() {
    let app = build_app();
    let response = app
        .oneshot(
            Request::builder()
                .uri("/users/me")
                .header("authorization", "Basic Zm9vOmJhcg==")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}

#[tokio::test]
async fn me_with_garbage_token_returns_401() {
    let app = build_app();
    let response = app
        .oneshot(
            Request::builder()
                .uri("/users/me")
                .header("authorization", "Bearer not.a.real.jwt")
                .body(Body::empty())
                .unwrap(),
        )
        .await
        .unwrap();
    assert_eq!(response.status(), StatusCode::UNAUTHORIZED);
}

#[test]
fn jwks_url_appends_well_known_path() {
    assert_eq!(
        iter_server::auth::jwks_url_from_supabase_url("https://abc.supabase.co"),
        "https://abc.supabase.co/auth/v1/.well-known/jwks.json"
    );
    // Trailing slash tolerated.
    assert_eq!(
        iter_server::auth::jwks_url_from_supabase_url("https://abc.supabase.co/"),
        "https://abc.supabase.co/auth/v1/.well-known/jwks.json"
    );
}
