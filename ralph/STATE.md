# Ralph Loop State

## Current
- iteration: 8
- last_completed: F0.3 (DB live), F0.6 (CI commit, push gated on token scope)
- in_progress: F0.4 Android — photo_manager UI shipped, device GPS extraction verification pending user
- last_run_at: 2026-05-15T23:30:00Z

## Resume-now checklist (for next session)

1. **Push F0.6 + F0.4** — currently 3 commits ahead of origin/master. Push is gated on adding `workflow` scope to the active GitHub token. User runs:
   ```
   gh auth refresh -h github.com -s workflow
   ```
   Then `git push origin master` clears the queue.
2. **Finish F0.4 Android device verify** — relaunch the spike on the Galaxy Fold 5:
   ```
   cd app
   flutter run -d 192.168.219.101:34571
   ```
   (If wireless ADB session expired, re-pair with a fresh pairing code from the phone — see iter 7 entry below.)
   On the phone: tap **Load recent photos** → grant the **Photos and videos** + **Media location** permissions → tap a thumbnail of a photo known to have GPS (camera-taken outdoor shot, not a screenshot or KakaoTalk-received image). Expected screen: real decimal lat/lng + MediaStore lat/lng + timestamp + camera model. The "✅ EXIF GPS extracted" line confirms the spike. ADR-001 (EXIF spike outcome) then gets written and F0.4 Android half flips to done. iOS half stays deferred per ADR-006 (macOS host required).
3. **F0.3 schema lifecycle note** — schema is live on Supabase via the Session pooler URL. The `_sqlx_migrations` bookkeeping row is in the DB so future migrations apply cleanly via sqlx-cli.

## Recent (last 20)
*This section will be trimmed to 20 entries by state-updater.*

- F0.4 🔧 2026-05-15 (iter 8) — IN PROGRESS: First spike attempt with image_picker on Galaxy Fold 5 (Android 16) returned `[0/0, 0/0, 0/0]` for GPSLatitude/Longitude even after declaring ACCESS_MEDIA_LOCATION. Root cause: Android 13+ Photo Picker (the system component image_picker invokes) unconditionally scrubs GPS for privacy — no flag bypasses it. Swapped to **photo_manager** which reads MediaStore directly and returns originBytes with EXIF intact when ACCESS_MEDIA_LOCATION is granted at runtime. New spike UI: horizontal thumbnail strip of last 24 photos, tap-to-parse. flutter analyze + flutter test green. Device verification of actual GPS extraction pending user's next session. See ADR-008.
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
