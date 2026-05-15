# Ralph Loop State

## Current
- iteration: 4
- last_completed: F0.5 (partial — Rust emission shipped; Dart codegen blocked on F0.1)
- in_progress: none
- last_run_at: 2026-05-15T20:10:00Z

## Recent (last 20)
*This section will be trimmed to 20 entries by state-updater.*

- ADR-005 ✅ 2026-05-15 — Tech-stack pivot: Mapbox → MapLibre GL + OpenFreeMap (free, no API key). Updated CLAUDE.md, srs/06, srs/07, FEATURE_BACKLOG F2.4/F3.1, .env.example. No active code yet (F3 not started).
- F0.5 ⚠️ 2026-05-15 — PARTIAL: utoipa-driven OpenAPI emission + memory-gated codegen.sh shipped; Dart client deferred to F0.1 (see BLOCKERS + ADR-003/004). NOTE: this iteration first aborted on memory gate (external rust build using 18 GB); succeeded on retry.
- F0.3 ⚠️ 2026-05-15 — PARTIAL: schema migration + optional sqlx pool + JSON /health shipped autonomously; Supabase credentials deferred to human (see BLOCKERS + ADR-002).
- F0.1 ⚠️ 2026-05-19 — BLOCKED: Flutter CLI not installed. Requires Flutter SDK installation before app scaffold can be created.
- F0.2 ✅ 2026-05-15 — Rust scaffold (axum 0.7 + sqlx + utoipa + supabase-jwt). /health endpoint live, cargo test green.
