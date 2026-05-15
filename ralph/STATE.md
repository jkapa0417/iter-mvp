# Ralph Loop State

## Current
- iteration: 8
- last_completed: F0.3 (DB live), F0.4 Android (spike verified end-to-end), F0.6 (CI commit local)
- in_progress: none for autonomous loop. Two human-only items remain — see resume checklist.
- last_run_at: 2026-05-16T00:30:00Z

## Resume-now checklist (for next session)

1. **Push everything** — currently several commits ahead of origin/master. Push is gated on adding `workflow` scope to the active GitHub token. User runs ONCE:
   ```
   gh auth refresh -h github.com -s workflow
   ```
   Then `git push origin master` clears the queue (F0.5/F0.6/F0.3/F0.4/F0.4-spike-result all push together).
2. **F0.4 iOS half** — remains deferred until macOS+Xcode is available. Same constraint as F0.1 iOS half (ADR-006). When a macOS host appears, run the same photo_manager spike there, verify HEIC pickup + EXIF GPS, then close the iOS half (write the result inside ADR-009's iOS section).
3. **All other F0.x bootstrap is closed.** F1.x can start: F1.1 (Supabase Auth in Flutter) is now unblocked because F0.3 (DB live), F0.5 (Dart client at packages/openapi/), and F0.1 (Android scaffold) all landed.

## Recent (last 20)
*This section will be trimmed to 20 entries by state-updater.*

- F0.4 ✅ 2026-05-16 (iter 8 continued) — DONE for Android. Spike verified end-to-end on Galaxy Z Fold 5 (Android 16): a freshly captured outdoor photo yielded EXIF lat `37.568552`, lng `126.839713`, MediaStore latlng matching to 6 decimal places, DateTimeOriginal + camera Make/Model preserved. Confirms (a) photo_manager bypasses the Android 13+ Photo Picker redaction, (b) the `_gps` DMS-to-decimal helper is correct, (c) MediaStore and EXIF are two independent paths that agree (strong evidence). Spike screen also classified three real-world states: GPS present (camera-original), GPS zeroed (image_picker path, never on photo_manager), GPS absent (messenger-received photos, no Image Make/Model either). Newest-first ordering required explicit FilterOptionGroup. See ADR-009. iOS half remains environment-deferred.
- F0.4 🔧 2026-05-15 (iter 8) — IN PROGRESS (later resolved above): First spike attempt with image_picker on Galaxy Fold 5 returned `[0/0, 0/0, 0/0]` regardless of ACCESS_MEDIA_LOCATION. Root cause: Android 13+ Photo Picker scrubs GPS at OS level. Swapped to photo_manager → custom thumbnail grid → originBytes → exif parse. See ADR-008.
- F0.6 ✅ 2026-05-15 (iter 7) — DONE (commit local, push gated): `.github/workflows/ci.yml` with 4 jobs (rust check+test, flutter analyze+test, dart-openapi analyze+test, sqlx migrate against postgres:16-alpine service). Acceptance text said "sqlx migrate run --dry-run" but sqlx-cli has no such flag; running against a real Postgres service is strictly stronger. Push refused by GitHub because active `jkapa0417` OAuth token lacks `workflow` scope — user must run `gh auth refresh -h github.com -s workflow` once, then F0.5/F0.6/F0.3/F0.4 all push together.
- F0.3 ✅ 2026-05-15 (iter 7) — DONE: Supabase project created and `.env` populated by user (URL, anon, service_role, DATABASE_URL). Direct hostname `db.<ref>.supabase.co:5432` is IPv6-only and WSL2 has no IPv6 routing → first connect attempts failed "Network is unreachable". User switched DATABASE_URL to the **Session pooler** (`postgres.<ref>@aws-1-ap-south-1.pooler.supabase.com:5432/postgres`, IPv4 ✓, included in the free tier — confused initially with Dedicated Pooler which is paid). `sqlx migrate run --source infra/supabase/migrations` applied migration 0001 in ~700ms. /health verified `{"status":"ok","db":"connected"}` 5/5 calls ~260ms p50. Server-side connection layer hardened: eager pool warm-up at startup, min_connections(1), idle_timeout(30s), test_before_acquire(true), /health timeout raised 500ms→1500ms. Removed F0.3 from BLOCKERS.
- F0.5 ✅ 2026-05-15 (iter 6) — DONE: `scripts/codegen.sh` runs end-to-end (cargo→openapi.json→openapi-generator-cli@7.22.0→dart format→dart pub get→build_runner). Dart client lives at `packages/openapi/` (project-root sibling). First attempt placed it under `app/lib/api/` which Flutter analyze recursively walked; relocated to fix. See ADR-007. F0.5 removed from BLOCKERS.
- F0.1 ⚠️ 2026-05-15 (iter 5) — PARTIAL: `flutter create app/` shipped (iOS+Android). Android verified (analyze + test green, debug APK 145 MB). iOS scaffold present but unbuildable in WSL2. See ADR-006.
- F0.1 🔓 2026-05-15 — UNBLOCKED: Flutter 3.41.9 SDK installed at ~/flutter, Android cmdline-tools at ~/Android (SDK 36 + build-tools 28.0.3 + platform-tools), JDK 21 present.
- ADR-005 ✅ 2026-05-15 — Tech-stack pivot: Mapbox → MapLibre GL + OpenFreeMap (free, no API key).
- F0.5 ⚠️ 2026-05-15 (iter 4) — PARTIAL: utoipa-driven OpenAPI emission shipped; Dart client deferred to F0.1.
- F0.3 ⚠️ 2026-05-15 (iter 3) — PARTIAL: schema migration + optional sqlx pool + JSON /health shipped; Supabase credentials deferred to human.
- F0.1 ⚠️ 2026-05-19 — BLOCKED: Flutter CLI not installed.
- F0.2 ✅ 2026-05-15 — Rust scaffold (axum 0.7 + sqlx + utoipa + supabase-jwt). /health endpoint live, cargo test green.

## Networking notes (carry across sessions)

- **Supabase networking**: WSL2 has no IPv6 routing. Direct DB hostname `db.<ref>.supabase.co` is IPv6-only on the Free tier; use the **Session pooler** (port 5432, IPv4, free) for sqlx-cli and the Rust server. Transaction pooler (port 6543) breaks sqlx prepared statements. See .env (not committed) for the current pooler URL.
- **Wireless ADB**: Pairing code in Phone → Developer options → Wireless debugging is valid only while that dialog is open. Pair port and connect port differ. Last session pair: `192.168.219.101:37371` code `024377`; connect: `192.168.219.101:34571`. Next session will likely need a fresh pairing.
- **GitHub token scope**: Active account `jkapa0417` token currently has `gist, read:org, repo` — needs `workflow` added to push the F0.6 commit.
