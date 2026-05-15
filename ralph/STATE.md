# Ralph Loop State

## Current
- iteration: 5
- last_completed: F0.1 (partial — Android verified; iOS scaffolded, deferred to macOS host)
- in_progress: none
- last_run_at: 2026-05-15T21:30:00Z

## Recent (last 20)
*This section will be trimmed to 20 entries by state-updater.*

- F0.1 ⚠️ 2026-05-15 — PARTIAL: `flutter create app/` shipped (iOS+Android targets). Android verified end-to-end (analyze, test, debug APK 145 MB). iOS scaffolded but unbuildable in WSL2 (no Xcode). T5 first attempt failed on missing openjdk-21-jdk → user installed → Gradle daemon caching tripped retry → `./gradlew --stop` + JAVA_HOME export cleared. See ADR-006.
- F0.1 🔓 2026-05-15 — UNBLOCKED: Flutter 3.41.9 SDK installed at ~/flutter, Android cmdline-tools at ~/Android (SDK 36 + build-tools 28.0.3 + platform-tools), JDK 21 present. `flutter doctor` green for Flutter/Android/device/network. F0.1 removed from BLOCKERS — next loop iteration will scaffold the app.
- ADR-005 ✅ 2026-05-15 — Tech-stack pivot: Mapbox → MapLibre GL + OpenFreeMap (free, no API key). Updated CLAUDE.md, srs/06, srs/07, FEATURE_BACKLOG F2.4/F3.1, .env.example. No active code yet (F3 not started).
- F0.5 ⚠️ 2026-05-15 — PARTIAL: utoipa-driven OpenAPI emission + memory-gated codegen.sh shipped; Dart client deferred to F0.1 (see BLOCKERS + ADR-003/004). NOTE: this iteration first aborted on memory gate (external rust build using 18 GB); succeeded on retry.
- F0.3 ⚠️ 2026-05-15 — PARTIAL: schema migration + optional sqlx pool + JSON /health shipped autonomously; Supabase credentials deferred to human (see BLOCKERS + ADR-002).
- F0.1 ⚠️ 2026-05-19 — BLOCKED: Flutter CLI not installed. Requires Flutter SDK installation before app scaffold can be created.
- F0.2 ✅ 2026-05-15 — Rust scaffold (axum 0.7 + sqlx + utoipa + supabase-jwt). /health endpoint live, cargo test green.
