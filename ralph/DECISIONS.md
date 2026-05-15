# Architectural Decisions — ITER MVP

> ADR-style log. Append-only. When a decision is made, add a new entry at the top.

---

### ADR-008 — Photo pipeline uses `photo_manager`, not `image_picker`, on Android (GPS scrubbing)

**Status:** Accepted

**Date:** 2026-05-15

**Context:**
F0.4 (EXIF spike) needs to extract GPS lat/lng/taken_at from real photos on a real Android device. First implementation used the canonical Flutter package `image_picker` to invoke the gallery picker. On a Galaxy Fold 5 (Android 16), every photo picked — even outdoor camera-taken shots known to carry GPS in the original file — returned `GPSLatitude = [0/0, 0/0, 0/0]` and `GPSLongitude = [0/0, 0/0, 0/0]` from the `exif` package, parsing to `NaN`. Adding `ACCESS_MEDIA_LOCATION` to AndroidManifest.xml and a full rebuild did NOT change the result.

Root cause: Android 13+ ships a system **Photo Picker** component (`ACTION_PICK_IMAGES`) which `image_picker` invokes via the Activity Result Contracts API. This Photo Picker, by design, **unconditionally redacts location EXIF** from the returned file copy before the requesting app receives it. The redaction is a privacy hardening built into the system component itself — no permission flag, intent extra, or plugin parameter bypasses it. This is documented Android security behavior, not a bug.

To get un-redacted EXIF on Android 13+ an app must either (a) use the older `Intent.ACTION_PICK` flow (deprecated, will break on future Android versions), (b) read directly from the MediaStore with `ACCESS_MEDIA_LOCATION` granted, or (c) ship a custom in-app gallery UI that talks to the asset library API.

**Decision:**
- Spike + future F2.x photo pipeline use **`photo_manager`** (Flutter package, ~3.6+). It implements path (b) above: queries MediaStore directly with `ACCESS_MEDIA_LOCATION`, returns `AssetEntity.originBytes` which carries full EXIF including unredacted GPS rationals.
- The F0.4 spike screen now: (i) calls `PhotoManager.requestPermissionExtend(... mediaLocation: true)`, (ii) renders a horizontal strip of recent `AssetEntity` thumbnails, (iii) on tap reads `originBytes`, parses via `package:exif`, cross-checks against `AssetEntity.latlngAsync()`.
- `image_picker` is removed from `app/pubspec.yaml`. F2.1 (photo picker UI) will be built on photo_manager primitives.

**Consequences:**
- F2.x design baseline: we ship our own thumbnail grid UI, we never rely on the Android system Photo Picker. iOS uses photo_manager too (single package across platforms, asks for "Full Access" permission per Apple docs).
- Spike acceptance language updated: extraction is verified via the photo_manager path, not the image_picker path that the original SRS implied.
- The `0/0` failure mode is preserved as an explicit `NaN` in the spike screen with a "OS likely stripped GPS — needs ACCESS_MEDIA_LOCATION or photo_manager" diagnostic; if it ever shows up after this ADR, it means photo_manager's permission request did not include `mediaLocation: true` (regression sentinel).
- APK size grows ~1-2 MB from photo_manager's native side. Acceptable.
- Android 14+ adds a "selected photos" partial-access permission mode; photo_manager handles this gracefully (PermissionState.limited), but UX needs to surface the "Select more photos" affordance later. Out of scope for the spike.

---

### ADR-007 — Generated Dart client lives at project root `packages/openapi/`, not `app/lib/api/`

**Status:** Accepted

**Date:** 2026-05-15

**Context:**
F0.5 acceptance originally said "openapi-generator creates Dart client in `app/lib/api/`". When iter 6 re-ran `scripts/codegen.sh` with `app/` finally present, two problems surfaced:
1. **The dart-dio generator writes a *standalone Dart package*** — its own `pubspec.yaml`, `lib/`, `test/`, deps (`dio`, `built_value`, `built_collection`, dev deps `build_runner`, `built_value_generator`), `analysis_options.yaml`. Dropping that inside `app/lib/api/` creates a nested package, which `flutter analyze` recursively walks and flags the generated code's warnings ("Analyzing app… 1 issue found … packages/openapi/lib/src/api/system_api.dart unused_import"). The Flutter app's `lib/` is the wrong home for an autonomous Dart package.
2. **The original script's `flutter pub run build_runner build` ran from `$APP_DIR`** — but build_runner + built_value_generator are dev_deps of the *generated* package, not the Flutter app. So build_runner couldn't find itself. ("Could not find package 'build_runner'. Did you forget to add a dependency?")

**Decision:**
- **Output location:** `packages/openapi/` at the project root, sibling to `app/`, `server/`, `infra/`. Matches the existing top-level layout (one directory per logical unit).
- **`scripts/codegen.sh`:** `DART_OUTPUT="$PROJECT_ROOT/packages/openapi"`; build_runner step runs `dart pub get && dart run build_runner build --delete-conflicting-outputs` from inside that directory using `dart`, not `flutter` (the openapi package is a pure Dart library, not a Flutter package).
- **Acceptance language updated** in `ralph/FEATURE_BACKLOG.md` to read "in `packages/openapi/`" with this ADR cross-referenced.

**Consequences:**
- `flutter analyze` from `app/` is now clean (no recursive descent into a non-dependency package).
- When F1.x needs to call the API, `app/pubspec.yaml` adds `openapi: { path: ../packages/openapi }` (standard Flutter monorepo pattern). Not added in F0.5 to keep this iteration's blast radius minimal — no app code consumes the client yet.
- `openapitools.json` (version-pinning to openapi-generator-cli 7.22.0) is now at the project root and is committed; codegen reproduces deterministically.
- The generator emits one harmless `unused_import` warning in `system_api.dart` (upstream template, not our code). Suppressing it would mean editing generated code; left as-is.
- The `--delete-conflicting-outputs` flag is silently ignored in build_runner ≥2.x. Kept in the script for backward compatibility; harmless warning at runtime.

---

### ADR-006 — F0.1 ships partial: Android verified, iOS deferred to macOS host

**Status:** Accepted

**Date:** 2026-05-15

**Context:**
F0.1's acceptance includes "Basic app runs on both platforms." The dev environment is WSL2 on Ubuntu 24.04 — iOS builds require macOS + Xcode + CocoaPods, none of which are available. Three options: (a) hard-block F0.1, (b) mark `done` and ignore the iOS half, (c) ship partial with iOS deferred.

**Decision:**
Option (c). In iteration 5:
- `flutter create --org app.iter --project-name iter --platforms=ios,android app` ran cleanly. Both `app/android/` and `app/ios/` trees are scaffolded correctly per Flutter 3.41.9 stable defaults.
- Android verified end-to-end: `flutter pub get` ✓, `flutter analyze` ✓ ("No issues found!"), `flutter test` ✓ ("All tests passed!"), `flutter build apk --debug` ✓ (145 MB APK at `app/build/app/outputs/flutter-apk/app-debug.apk`).
- iOS scaffold present but `flutter build ios` not attempted — known unbuildable in WSL2.
- Build dependencies installed during this iteration: `openjdk-21-jdk` (user ran `sudo apt install`), Android Build-Tools 35.0.0, CMake 3.22.1, NDK 28.2.13676358 (auto-installed by Gradle on first build).

**Consequences:**
- F0.1 acceptance "runs on both platforms" half-met. Future macOS contributor (or macOS-based CI runner — likely F0.6 territory) must run `cd app/ios && pod install && flutter build ios` to fully close F0.1.
- F0.4 (EXIF spike) and F0.5 (Dart client generation) are unblocked since both only need `app/` to exist.
- F1.1 (Supabase Auth in Flutter), F2.x (photo pipeline), F3.x (MapLibre map) can all begin once their other dependencies clear.
- `~/.zshrc` now exports `PATH` for `~/flutter/bin` and `~/Android/cmdline-tools/latest/bin`; also exports `ANDROID_HOME=$HOME/Android` and `ANDROID_SDK_ROOT=$HOME/Android`. Builds also require `JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64` set in the shell (not yet in .zshrc — should be added before F0.6 CI).
- Gradle daemon caching bit us on the first T5 attempt — second attempt with `./gradlew --stop` cleared the cache. Documented for future build issues.

---

### ADR-005 — Swap Mapbox for MapLibre GL + OpenFreeMap vector tiles

**Status:** Accepted

**Date:** 2026-05-15

**Context:**
The original SRS specified Mapbox (`mapbox_maps_flutter`) for the world map. Mapbox's free tier caps at 50k map loads/month, after which it charges $5/1k. For an MVP that wants to grow without billing friction (and with a user who specifically wants to avoid a credit card requirement for the project), this is a hard ceiling. The user explicitly approved exploring open-source alternatives.

**Decision:**
- **Renderer:** MapLibre GL via the `maplibre_gl` Flutter plugin. MapLibre is a community-maintained fork of Mapbox GL v1 (the last open-source release), so the rendering API is essentially identical to Mapbox GL — vector tiles, GeoJSON sources with clustering, layer filters for country fills, etc. all work the same way.
- **Tile source:** OpenFreeMap (https://openfreemap.org), an open-source vector tile service launched in 2024. No API key, no rate limits, OpenMapTiles schema. Free forever per their charter.
- **Backup tile source:** Stadia Maps free tier (200k req/month) configurable via `MAP_TILE_URL` env var if OpenFreeMap is ever unreachable.
- **Geocoding:** Nominatim (OpenStreetMap) replaces Mapbox Geocoding for the F2.4 search picker. 1 req/s rate limit, requires User-Agent header. For F2.5 country code extraction we use offline point-in-polygon against Natural Earth GeoJSON (~2 MB asset) — no network calls, faster and free.

**Consequences:**
- **MVP cost ceiling removed.** Zero recurring map costs, ever.
- **No vendor lock-in.** If OpenFreeMap shuts down (unlikely), the tile-source env var swaps providers without a rebuild. Long-term we can self-host OpenMapTiles.
- **SRS updates:** `srs/06-geo-logic.md` adds a "Map Rendering Stack" section; `srs/07-risks.md` replaces "Mapbox Usage Cost" with "Map Tile Source Availability"; `CLAUDE.md` line 7 swaps the Maps stack. F2.4 and F3.1 acceptance criteria updated in `ralph/FEATURE_BACKLOG.md`.
- **`.env.example`:** `MAPBOX_ACCESS_TOKEN` removed; replaced with `MAP_TILE_URL` (default OpenFreeMap) and optional `MAP_TILE_API_KEY` for paid-tier fallbacks.
- **Slight visual difference:** the default OpenFreeMap style ("Liberty") is less polished than Mapbox's default styles. MapLibre style JSON is hand-editable and we can fork the style file to match brand tokens (`srs/05-ui-design.md`) when we get to F3.x.
- **Nominatim rate-limit (1 req/s):** F2.4 must debounce the search input. This is good UX anyway, so no real cost.

---

### ADR-001 — Supabase JWT verification approach

**Status:** Accepted

**Date:** 2026-05-15

**Context:**
F0.2 requires the Rust server manifest to carry a Supabase JWT verification dependency so F1.2 (JWT middleware) can build on top without further bootstrapping. Supabase Auth issues ES256 JWTs verified via a JWKS endpoint.

**Decision:**
We use `supabase-jwt = "0.1"` (latest: v0.1.1, released 2025-08-10). This crate is a lightweight, framework-agnostic library that validates Supabase Auth JWTs using a cached JWKS endpoint. It was released within the last 12 months and directly addresses our use case, avoiding the need to combine `jsonwebtoken` + manual JWKS fetching via `reqwest`.

**Consequences:**
F1.2 implementation will wrap `supabase-jwt` in an Axum tower middleware layer. The crate handles JWKS caching internally, so no custom cache management is needed. No DB or network access at startup; verification is lazily initialized when F1.2 lands.

---

### ADR-002 — F0.3 pre-staged: schema + sqlx wiring delivered, credentials deferred

**Status:** Accepted

**Date:** 2026-05-15

**Context:**
F0.3 requires a Supabase project + real `DATABASE_URL` credentials, neither of which the autonomous Ralph Loop can obtain (Supabase project creation requires browser OAuth). Two options: (A) hard-block F0.3 entirely like F0.1; (B) deliver the schema + Rust-side wiring now and partial-block on credentials.

**Decision:**
Option B. In iteration 3:
- Authored `infra/supabase/migrations/0001_init.sql` from `srs/02-data-model.md` (4 core tables: users, trips, posts, countries_visited; RLS enabled; policy stubs as comments).
- Added optional `init_db_pool() -> Option<PgPool>` in `server/src/lib.rs` so server starts without `DATABASE_URL`.
- Enriched `/health` to report DB readiness as `{"status":"ok","db":"unconfigured|connected|disconnected"}` — additive over `srs/03-api.md`'s `200 OK` contract.
- Schema deviations from SRS (justified in migration comments):
  - `posts.trip_id ON DELETE SET NULL` (not CASCADE) — trips are organizational, not ownership.
  - `NOT NULL` on FK `user_id` columns — tightens SRS to eliminate orphan-row class of bugs.
- Chose `--source` CLI flag over a populated `sqlx.toml` because the sqlx 0.8 toml schema is not reliably documented for the current CLI version.

**Consequences:**
- F1.x can now build on a known-good schema; F1.3 (user profile bootstrap) only needs to add the auth.uid() linkage column on `users` and apply the policy stubs as real `CREATE POLICY` statements.
- F0.6 (CI skeleton) can run `cargo check` / `cargo test` without a database — verified.
- F0.3 stays `[ ] blocked` until a human completes the 6-step handoff in README. Reverting this partial work would cost real schema design effort already validated against the SRS.
- `supabase-jwt` crate stays declared-but-unused in `server/Cargo.toml` (carried over from F0.2); will become active in F1.2.

---

### ADR-003 — F0.5 chose npx openapi-generator-cli over docker

**Status:** Accepted

**Date:** 2026-05-15

**Context:**
F0.5's `scripts/codegen.sh` originally invoked `docker run openapitools/openapi-generator-cli`. Docker is not available in this WSL2 environment. Three alternatives: (a) install docker, (b) install openapi-generator-cli natively (Java dep), (c) use the official npm wrapper via npx.

**Decision:**
Use `npx --yes @openapitools/openapi-generator-cli generate ...`. Node 22 + npx are already present. The npm wrapper downloads the generator JAR on first use (~50 MB) and caches it.

**Consequences:**
- No docker dependency. Works in any environment with cargo + node.
- First run downloads JAR; subsequent runs are fast.
- Identical generator semantics to the docker image (same upstream binary).
- Script still gates the Dart-client step on `command -v npx` for portability.

---

### ADR-004 — F0.5 hand-rolled `--emit-openapi` flag, no clap dependency

**Status:** Accepted

**Date:** 2026-05-15

**Context:**
The `--emit-openapi` mode needs to short-circuit normal server startup, print the OpenAPI JSON to stdout, and exit before tracing pollutes the output. Two implementation choices: pull in `clap` for proper arg parsing, or hand-roll a single-flag check.

**Decision:**
Hand-rolled — `if std::env::args().any(|a| a == "--emit-openapi") { ... }` at the top of `main.rs`. tracing-subscriber is also configured with `.with_writer(std::io::stderr)` as defense in depth.

**Consequences:**
- One less dependency, one less compile-time hit.
- If we ever need >2 CLI flags, revisit and switch to clap.
- Tracing → stderr is now a project invariant; never log to stdout from this binary.

---

## Template

### ADR-XXX — [Title]

**Status:** Accepted / Proposed / Deprecated / Superseded

**Date:** YYYY-MM-DD

**Context:**
What problem are we solving? What are the constraints?

**Decision:**
What did we decide?

**Consequences:**
What does this mean for the project?

---

