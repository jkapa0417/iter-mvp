# iter-server

Rust backend for the ITER MVP (Axum + sqlx + utoipa).

## Run

```bash
cargo run
# Optional: PORT=3000 cargo run
```

## Verify

```bash
curl localhost:8080/health
# → ok
```

## Roadmap

- **F0.3**: Supabase Postgres connection (`DATABASE_URL` env var, sqlx wiring)
- **F0.5**: utoipa OpenAPI annotations + codegen for Dart client
- **F1.2**: JWT middleware using `supabase-jwt` (JWKS-cached ES256 verification)
