# SRS 04 — Non-Functional Requirements — ITER MVP

## Performance
- **Map load**: <500ms p95 (tile loading + pins)
- **Photo upload**: <2s end-to-end (including EXIF extraction)
- **Profile API**: <100ms p95
- **Feed API**: <200ms p95 (paginated)

## Privacy
- **Per-post visibility**: public / followers / private
- **Location precision**: Toggle (exact / city-only)
- **Default**: city-only precision on public profile, exact only to self
- **Data retention**: Soft-delete posts recoverable within 30 days

## Security
- **Auth**: Supabase JWT (ES256) verified via JWKS
- **RLS**: Enabled by default on all user data tables
- **Service-role**: Used by Rust backend only; bypasses RLS for server-side writes
- **Photo URLs**: Signed + short-lived (15min) via Supabase Storage

## Observability
- **Logging**: Structured logs via `tracing` crate (Rust)
- **Crash reporting**: Sentry for Flutter + Rust
- **Metrics**: Basic counters (posts_created, auth_events, map_loads)

## Platform Support
- **iOS**: 15+
- **Android**: 8+ (API 26+)
- **Flutter**: 3.24+ stable channel

## To Be Expanded
Full observability stack and rate-limiting strategy defined during F1 (Auth) implementation.
