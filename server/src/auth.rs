// F1.2 — Supabase JWT verification middleware.
//
// Wraps `supabase_jwt` (ES256/JWKS) as an Axum tower middleware. Reads the
// `Authorization: Bearer <token>` header on every request, validates against
// the cached JWKS, and injects an `AuthUser` into the request extensions for
// downstream handlers. Failures map to 401 Unauthorized.

use axum::{
    extract::{Request, State},
    http::StatusCode,
    middleware::Next,
    response::Response,
};
use supabase_jwt::{Claims, JwksCache};

/// Identity of the authenticated caller, attached to the request after
/// middleware passes. Handlers retrieve it via
/// `axum::Extension<AuthUser>` extractor.
#[derive(Clone, Debug)]
pub struct AuthUser {
    pub user_id: String,
    pub email: Option<String>,
}

/// Build the JWKS URL for a given Supabase project URL.
///
/// Supabase serves its public keys at the RFC 8615 well-known path:
/// `https://<ref>.supabase.co/auth/v1/.well-known/jwks.json`. The older path
/// `/auth/v1/jwks` (mentioned in the `supabase-jwt` 0.1.1 docs) returns 401
/// "No API key found" on current Supabase deployments — the well-known path
/// is publicly readable without an `apikey` header.
pub fn jwks_url_from_supabase_url(supabase_url: &str) -> String {
    let trimmed = supabase_url.trim_end_matches('/');
    format!("{trimmed}/auth/v1/.well-known/jwks.json")
}

/// Axum middleware: require a valid Supabase JWT, inject `AuthUser`.
///
/// Returns 401 on any of:
/// - missing `Authorization` header
/// - header value not parseable as UTF-8
/// - bearer token validation failure (signature, expiry, audience, etc.)
///
/// Wire up with `from_fn_with_state(jwks_cache, require_auth)`.
pub async fn require_auth(
    State(jwks): State<JwksCache>,
    mut req: Request,
    next: Next,
) -> Result<Response, StatusCode> {
    let header = req
        .headers()
        .get(axum::http::header::AUTHORIZATION)
        .and_then(|h| h.to_str().ok())
        .ok_or(StatusCode::UNAUTHORIZED)?;

    let claims = Claims::from_bearer_token(header, &jwks).await.map_err(|e| {
        tracing::debug!("auth rejected: {e}");
        StatusCode::UNAUTHORIZED
    })?;

    let user = AuthUser {
        user_id: claims.user_id().to_string(),
        email: claims.email().map(|s| s.to_string()),
    };
    req.extensions_mut().insert(user);
    Ok(next.run(req).await)
}
