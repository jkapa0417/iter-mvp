# Architectural Decisions — ITER MVP

> ADR-style log. Append-only. When a decision is made, add a new entry at the top.

---

### ADR-011 — Globe package swap: flutter_earth_globe → flutter_globe_3d (rotation quality)

**Status:** Accepted

**Date:** 2026-05-16

**Context:**
ADR-010 selected `flutter_earth_globe` v2.2.1 for the 3D globe home view (Path A). On-device validation on Galaxy Z Fold 5 (Android 16, iter 12) surfaced unfixable issues:

1. **Rotation axis coupling** — `rotating_globe.dart:1771-1776` updates both `rotationX` and `rotationY` from `offset.dy` (vertical drag), which combines the axes once the globe has rotated some. Drag direction becomes inconsistent as the user rotates around — sometimes left-swipe rotates right, sometimes vertical input wraps onto X. UX-breaking for a globe-first app.
2. **Horizontal pan can't be inverted independently** — `panSensitivity` flips both X and Y. No separate `invertHorizontalPan` flag.
3. **Image flinch on drag** — MemoryImage path re-decodes per frame during gestures, causing the texture to flicker/snap to wrong positions.

Forking the package to fix the rotation math is non-trivial maintenance burden. Surveyed pub.dev for alternatives; **`flutter_globe_3d` v2.2.5** (different author, GPU fragment-shader-based rendering, "smooth gestures" advertised) was the only credible candidate.

**Decision:**
Swap to `flutter_globe_3d`. Validated on Fold 5:
- Rotation is clean and consistent across the full sphere (no axis coupling).
- Texture loads via standard `ImageProvider`; no flinch with `MemoryImage`.
- Built-in `EarthLightMode.fixedCoordinates` lets us pin the light to the camera focus → eliminates terminator shading via a controller listener (`setFixedLightCoordinates(currentLat, currentLng)` on every offset change).
- Square canvas locked to `min(width, height)` with `ValueKey(canvasSide)` recreation + zoom reset on viewport change handles foldable fold↔unfold cleanly.

**Consequences:**
- ADR-010 Path A still holds (two-screen globe → 2D country map). Only the globe-rendering package changed.
- `flutter_earth_globe` removed from `app/pubspec.yaml`.
- `app/lib/screens/globe_screen.dart` rewritten around `Earth3D` / `EarthController` / `EarthNode` API.
- Limitations carried into F3.x:
  - The package's pin tap propagates to globe gesture (tap rotates slightly). F3.3 will wrap pin children in an opaque hit-test region before navigating.
  - Auto-rotate resume timer is hardcoded ~1s in the package — we override with a `Listener` + 8s `Timer`.
  - `fixedCoordinates` light mode mathematics require manual sync to camera. Done via a controller listener that converts `offset → (lat, lng)` using the package's inverse projection formula (mirrors `setCameraFocus`).

---

### ADR-010 — Home screen: 3D globe + 2D country drill-down (two-screen architecture)

**Status:** Accepted

**Date:** 2026-05-16

**Context:**
Original SRS (`srs/05-ui-design.md`, `srs/06-geo-logic.md`) framed the home screen as a single MapLibre 2D map. User pivot: home should be a **3D globe** the user spins to find a country, and tapping a country **drills down to a 2D map** of that country with pins. Visual direction: "modern, abstract, not Google-Earth-realistic" — flat color palette, no terrain/cloud textures, minimal labels.

Spike of `maplibre_gl` v0.26.1 confirmed it does **not** expose MapLibre Native's globe projection (no `setProjection` / `globe` symbols across the plugin trio). One-map continuous-zoom is therefore not available without a custom plugin patch.

Three forward paths were evaluated:

- **A.** Standalone 3D globe widget (`flutter_earth_globe` v2.2.1, active April 2026) for the home view; MapLibre 2D for the country-detail view; **Hero/fade transition** between screens.
- **B.** Patch `maplibre_gl` native bridges to expose `setProjection('globe')` → enables a single map with continuous zoom (true Google-Earth-style transition).
- **C.** WebView with MapLibre GL JS (globe-capable on web).

**Decision:**
**Path A.** Two-screen home: 3D globe → 2D country map, joined by a Hero/fade transition (~400ms). Chosen because:
- ~1 day vs ~2–3 days (B) or WebView UX trade-offs (C).
- `flutter_earth_globe` surface is a custom equirectangular PNG, giving us pixel-level control of the globe's aesthetic (palette, abstraction level, country fills) without touching native code.
- Visited countries rendered into the globe texture at runtime via Flutter Canvas API + Natural Earth GeoJSON (offline; no extra dependency).
- Country pick on globe → fade to MapLibre 2D country view sharing the same color tokens. UX continuity comes from style consistency, not literal pixel-continuous zoom.

**Consequences:**
- Home view is `GlobeScreen` (3D), tap-to-drill-down navigates to `CountryMapScreen` (2D MapLibre with country-bounded camera).
- SRS updates required (deferred until F3.x implementation actually starts; ADR is the source of truth meanwhile):
  - `srs/05-ui-design.md` — home screen replaced with globe; country detail screen added.
  - `srs/06-geo-logic.md` — "Map Rendering Stack" section gains `flutter_earth_globe` for the globe; MapLibre stays as-is for country detail.
- `FEATURE_BACKLOG.md` F3.x re-mapped:
  - F3.1 → 3D globe widget (was: MapLibre map widget)
  - F3.2 → Render visited countries onto globe texture (was: render pins)
  - F3.3 → Tap country → fade to 2D MapLibre country view
  - F3.4 → Pins on 2D country view (was: country fill coloring)
  - F3.5 → Country fill + depth coloring (lives on the 2D country view, and on the globe texture)
  - The depth-coloring logic (`srs/06-geo-logic.md`) survives unchanged; it just rasterizes into the globe PNG + applies as MapLibre fill on country view.
- Future-proofing: if `maplibre_gl` ships globe projection later, we can collapse to Path B (single map) in v1.x without a SRS rewrite — the visual is the same.
- Performance ceiling: globe + a few hundred pins is fine on Fold-class devices. Thousands of pins would need clustering before placing on the globe; F3.2 keeps clustering as a known-required follow-up.

---

### ADR-009 — F0.4 EXIF spike outcome (Android verified, iOS deferred)

**Status:** Accepted

**Date:** 2026-05-15

**Context:**
F0.4 was the toolchain-validation spike: prove that, on a real device, the Flutter photo pipeline can pull GPS lat/lng plus the original capture timestamp from a user-picked photo. Two device halves were required by the SRS (iOS HEIC + Full-Access permission; Android JPEG). iOS half is environment-blocked (no macOS host — see ADR-006). The Android half was exercised on a Galaxy Z Fold 5 running Android 16 in iter 8.

**Decision (the spike's empirical findings):**

1. **`image_picker` on Android 13+ is unusable for our pipeline.** The system Photo Picker the plugin invokes returns `GPSLatitude = [0/0, 0/0, 0/0]` and `GPSLongitude = [0/0, 0/0, 0/0]` for every picked photo, including originals known to carry GPS, regardless of `ACCESS_MEDIA_LOCATION` permission. This is an OS-level redaction in the Photo Picker system component, not a plugin bug. See ADR-008 for the swap rationale.

2. **`photo_manager` + `package:exif` works end-to-end.** With permission requested via `PhotoManager.requestPermissionExtend(... mediaLocation: true)`, `AssetEntity.originBytes` returns the un-redacted file content. Galaxy Z Fold 5 capture verified:
   ```
   raw GPS lat:     [37, 34, 6787919/1000000]    ← real Rational triple
   EXIF lat:        37.568552                     ← DMS-to-decimal conversion correct
   MediaStore lat:  37.56855219972223             ← independent path matches 6 digits
   EXIF lng:        126.839713
   MediaStore lng:  126.83971289972222            ← independent path matches 6 digits
   taken_at:        2026:05:15 23:05:59           ← DateTimeOriginal preserved
   camera:          samsung Galaxy Z Fold5         ← Image Make/Model preserved
   ```
   EXIF and MediaStore agree to 6 decimal places of latitude/longitude — two independent extraction paths converging is strong evidence the toolchain is correctly wired.

3. **Source mix matters.** Non-camera photos in the user's gallery (KakaoTalk-received, downloaded, screenshots, edited) frequently lack GPS entirely (`GPSLatitude` tag absent, not zeroed). Some also lose `Image Make/Model`. The spike screen distinguishes these three states for the F2.x pipeline:
   - **GPS present** → ✅ feed F2.5 directly
   - **GPS zeroed (0/0)** → OS-strip case (image_picker only — should never occur on the photo_manager path)
   - **GPS absent (no tag)** → genuine missing metadata → F2.4 manual location picker required

4. **HEIC support on Android is implicit.** The Fold 5 emits JPEG by default; HEIC EXIF handling is exercised by iOS only and stays deferred with the iOS half.

5. **Order is not default.** photo_manager's default asset ordering is ascending (oldest first). Real-world UX demands newest-first; spike screen sets `FilterOptionGroup(orders: [OrderOption(type: createDate, asc: false)])` and F2.x will inherit.

**Consequences:**
- F0.4 Android half flips to `[x] done` in `FEATURE_BACKLOG.md`.
- F0.4 iOS half stays open, blocked on macOS host (parallel to F0.1 iOS half).
- F2.1 (photo picker UI) inherits this spike's pattern: PhotoManager.requestPermissionExtend → custom thumbnail grid → originBytes → exif parse. No image_picker.
- F2.2 (EXIF GPS extraction) inherits the `_gps` DMS-to-decimal helper and the three-state classification (present/zeroed/absent).
- F2.4 (manual location picker fallback) is now confirmed to be a real-traffic feature, not an edge case — most non-camera-original photos in user galleries will need it.
- Spike screen (`app/lib/main.dart`) stays in place as a dev-time diagnostic; it gets replaced by the real Post screen in F2.1 work.

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

