# Feature Backlog — ITER MVP

> Order is execution order. Dependencies must be satisfied. F0–F8 are MVP-critical; F9–F11 are stretch.

---

## F0 — Bootstrap

### F0.1 — Flutter app scaffold
- [ ] Status: partial (Android verified iter 5: APK built + analyze + test green; iOS scaffolded but build unverified — needs macOS+Xcode or macOS CI runner)
- Depends on: none
- Acceptance:
  - `flutter create app/` with iOS + Android targets
  - Latest stable Flutter channel
  - Basic app runs on both platforms
- SRS refs: srs/00-overview.md

### F0.2 — Rust server scaffold
- [x] Status: done
- Depends on: none
- Acceptance:
  - `cargo new server/ --bin`
  - Dependencies: axum, sqlx, utoipa, supabase_jwt, tokio, serde, tracing
  - `cargo check` passes
  - Hello-world `/health` endpoint returns 200
- SRS refs: srs/03-api.md

### F0.3 — Supabase + env vars setup
- [x] Status: done (iter 7)
- Depends on: F0.2
- Acceptance:
  - Supabase project created (`hqgfmuakvqnmwvlaevpg`, region ap-south-1) ✓
  - `.env` populated with URL, anon, service_role, DATABASE_URL ✓
  - `.gitignore` excludes `.env` ✓
  - `sqlx migrate run` (real, not --dry-run) applied 0001_init.sql in ~700ms ✓
  - /health returns `{"status":"ok","db":"connected"}` consistently ~260ms p50 ✓
- Implementation notes: WSL2 has no IPv6, so DATABASE_URL must use the **Session pooler** (`aws-1-ap-south-1.pooler.supabase.com:5432`, IPv4, free tier). Direct hostname `db.<ref>.supabase.co` is IPv6-only on Free tier and unreachable from WSL2.
- SRS refs: srs/02-data-model.md

### F0.4 — ⚠️ EXIF SPIKE (iOS + Android devices)
- [x] Status: done for Android (iter 8); iOS half deferred to macOS host (parallel to F0.1)
- Depends on: F0.1
- Acceptance:
  - Given a JPEG/HEIC picked from gallery on iOS device with "Full Access" permission → 🚧 deferred (macOS+Xcode required, see ADR-006)
  - And a JPEG picked from gallery on Android device → ✅ Galaxy Z Fold 5 (Android 16): EXIF lat 37.568552, lng 126.839713 extracted; MediaStore latlng matches to 6 decimal places; DateTimeOriginal + Galaxy Z Fold5 Make/Model preserved
  - When app extracts EXIF metadata → ✅
  - Then lat/lng/taken_at are successfully extracted and printed to console → ✅ (debugPrint dump captured in monitor output, iter 8)
  - And HEIC support is verified on iOS real device (simulator not accepted) → 🚧 deferred
  - Result documented as ADR-009 in DECISIONS.md ✓
- Implementation notes (iter 8):
  - Initial attempt with `image_picker` returned `0/0` GPS Rationals regardless of `ACCESS_MEDIA_LOCATION` — Android 13+ Photo Picker redacts at OS level. See ADR-008.
  - Swap to `photo_manager` + custom 4-col thumbnail grid + bottom-sheet result view fixed it.
  - Newest-first ordering required explicit `FilterOptionGroup(orders: createDate desc)`.
- SRS refs: srs/07-risks.md#ios-gps

### F0.5 — OpenAPI codegen pipeline
- [x] Status: done (iter 6)
- Depends on: F0.2
- Acceptance:
  - `scripts/codegen.sh` runs end-to-end ✓
  - Rust server emits OpenAPI spec ✓
  - openapi-generator creates Dart client in `packages/openapi/` (relocated from `app/lib/api/` — see ADR-007) ✓
  - Generated client builds without errors (`dart analyze` clean except 1 upstream-template unused_import; `dart test` 3/3 green; `flutter analyze` from app/ clean; `flutter test` from app/ green) ✓
- SRS refs: srs/03-api.md

### F0.6 — CI skeleton
- [x] Status: done (iter 7 — committed locally, push gated on token scope)
- Depends on: F0.1, F0.2
- Acceptance:
  - `.github/workflows/ci.yml` created ✓
  - Runs: flutter analyze + flutter test (app/), cargo check + cargo test (server/), dart analyze + dart test (packages/openapi/), sqlx migrate run against postgres:16-alpine service container ✓
  - "sqlx migrate run --dry-run" acceptance text deviated: sqlx-cli has no --dry-run flag; using a real postgres service container is strictly stronger
  - Pass-on-empty-repo verification pending first push (blocked: GitHub OAuth token for jkapa0417 lacks `workflow` scope — see STATE.md resume checklist)
- SRS refs: srs/04-nfr.md

---

## F1 — Auth

### F1.1 — Supabase Auth in Flutter (email/password)
- [x] Status: done (email/password; OAuth carved out as F1.1.5)
- Depends on: F0.3
- Acceptance:
  - Apple + Google sign-in working → carved out to F1.1.5 (needs platform plumbing — Apple Developer entitlement, Google Client ID, redirect URIs)
  - Email/password auth working ✓ (verified on Galaxy Z Fold 5 with `test@iter.local`)
  - Auth state persists across app restarts ✓ (cold-launch lands on HomeScreen with active session)
  - Unauthenticated state shows login screen ✓ (signed-out user lands on LoginScreen)
- Implementation notes:
  - `supabase_flutter` initialized in `main()` from `app/.env` (gitignored) via `flutter_dotenv`. Only `SUPABASE_URL` + `SUPABASE_ANON_KEY` go to the client; `SERVICE_ROLE_KEY` stays server-side.
  - `_AuthGate` subscribes to `Supabase.instance.client.auth.onAuthStateChange` and renders LoginScreen vs HomeScreen accordingly.
  - F0.4 EXIF spike screen replaced; the spike's outcome is preserved in ADR-009 + git history.
- SRS refs: srs/01-functional.md#auth

### F1.1.5 — OAuth sign-in (Apple + Google) — DEFERRED
- [ ] Status: pending
- Depends on: F1.1
- Acceptance:
  - Apple Sign-In configured (Apple Developer account, "Sign in with Apple" capability, services ID, redirect URI in Supabase)
  - Google Sign-In configured (Google Cloud Console OAuth client ID, redirect URI in Supabase)
  - Buttons on LoginScreen complete OAuth flow → session
- Notes:
  - LoginScreen already has the Apple/Google buttons wired with "coming soon" snackbars — UI shell ready.
  - Cannot proceed without paid Apple Developer enrollment.
- SRS refs: srs/01-functional.md#auth

### F1.2 — Rust JWT verification middleware
- [x] Status: done (iter 10)
- Depends on: F1.1, F0.2
- Acceptance:
  - ES256/JWKS verification via supabase_jwt crate ✓
  - Middleware rejects invalid tokens ✓ (no header / non-Bearer / garbage token all → 401, unit-tested)
  - Valid tokens pass user_id to handlers ✓ (real Supabase JWT → `/me` returns 200 with `{user_id, email}` matching the token's `sub` claim; verified end-to-end against `test@iter.local`)
- Implementation notes:
  - `server/src/auth.rs` — `AuthUser` extension type + `require_auth` tower middleware. Routes are split into a public group (`/health`) and a protected nested router (currently just `/me`) layered with `from_fn_with_state(jwks_cache, require_auth)`.
  - JWKS endpoint: `${SUPABASE_URL}/auth/v1/.well-known/jwks.json` (the `supabase-jwt` 0.1.1 docs point at the older `/auth/v1/jwks` path, which now returns 401 on Supabase — verified manually and corrected in our wrapper).
  - JwksCache is cheap to clone (internal Arc/RwLock), lives in `AppState` directly.
  - `/me` shape is the stand-in for F1.3 — F1.3 will replace its body with a DB-backed profile lookup.
  - Cold cache: ~44ms per request (JWKS fetch). Warm: <1ms.
- SRS refs: srs/04-nfr.md#security

### F1.3 — User profile bootstrap
- [x] Status: done (iter 11)
- Acceptance:
  - `users` table created ✓ (F0.3 — 0001_init.sql)
  - First login creates user row with default profile ✓ (auto-username `user_<8hex>`, email from JWT, empty bio/photo; verified end-to-end against `test@iter.local`)
  - `GET /users/me` returns current user profile ✓ (200 with full UserProfile; idempotent on repeat calls)
- Implementation notes:
  - Migration 0002 adds RLS policies (`users_select_own / users_insert_self / users_update_own`) — defense-in-depth; server uses postgres superuser via Session pooler and bypasses RLS for app-layer authz.
  - `server/src/users.rs` — single handler `get_or_bootstrap_me`. SELECT by `id = JWT.sub`; on miss, INSERT with `id = JWT.sub`, `username = format!("user_{}", &uuid.simple()[..8])`, `email = JWT.email`.
  - Replaced placeholder `/me` from F1.2; OpenAPI tag now `users` instead of `auth`.
  - Added direct deps: `uuid` (v4, serde) + `chrono` (serde, no-default).
  - codegen.sh: added "clean stale generated output" step — when API surface changes (renamed endpoint / removed schema), the generator leaves orphans that break `dart test`. Wipe is scoped to deterministic regen targets.
- SRS refs: srs/02-data-model.md#users (still backed by 0001_init schema)

---

## F2 — Photo Upload Pipeline

### F2.1 — Photo picker UI + permission gating
- [ ] Status: pending
- Depends on: F1.3
- Acceptance:
  - Native gallery picker opens
  - iOS shows "Full Access" permission explanation before picker
  - Selected photo preview shows
- SRS refs: srs/01-functional.md#post-screen, srs/07-risks.md#ios-gps

### F2.2 — EXIF GPS + taken_at extraction
- [ ] Status: pending
- Depends on: F2.1, F0.4
- Acceptance:
  - Extract lat/lng/taken_at using `exif` package
  - HEIC supported on iOS
  - Missing GPS triggers fallback flow (F2.4)
- SRS refs: srs/07-risks.md#ios-gps

### F2.3 — Upload to Supabase Storage
- [ ] Status: pending
- Depends on: F2.2
- Acceptance:
  - Photo uploaded to Supabase Storage bucket
  - Signed URL flow via Rust backend
  - Progress indicator shown
- SRS refs: srs/03-api.md#storage

### F2.4 — Manual location picker fallback
- [ ] Status: pending
- Depends on: F2.2
- Acceptance:
  - Nominatim search interface (OpenStreetMap geocoding, 1 req/s, debounced input, User-Agent header set)
  - Tap-to-place pin on MapLibre map
  - Required when GPS missing
- SRS refs: srs/01-functional.md#post-screen, srs/06-geo-logic.md#map-rendering-stack

### F2.5 — POST /posts API + DB write
- [ ] Status: pending
- Depends on: F2.3, F2.4
- Acceptance:
  - `POST /posts` creates post record
  - Validates auth, photo_url, lat/lng, taken_at
  - Returns created post
- SRS refs: srs/03-api.md#posts

---

## F3 — World Map (Home)

> ⚠️ F3.x re-mapped in ADR-010 — home pivot to 3D globe + 2D country drill-down. Original "single MapLibre 2D map" plan superseded. SRS update deferred to F3 implementation.

### F3.1 — 3D globe home widget (`flutter_globe_3d`)
- [x] Status: done (iter 12, concept-validated on Galaxy Z Fold 5)
- Depends on: F1.3
- Acceptance:
  - Full-screen 3D globe loads on home tab ✓
  - Custom equirectangular PNG texture (modern flat-color palette, no terrain/clouds/labels) ✓ — placeholder oval-blob continents painted via Flutter Canvas (F3.2 swaps to Natural Earth polygons)
  - User can rotate, zoom, tap a pin ✓
  - Tapping pin → "country drill-down coming in F3.3" snackbar (F3.3 wires the real Hero/fade to MapLibre)
- Package swap: ADR-010 originally selected `flutter_earth_globe` but on-device validation surfaced unfixable rotation-axis bugs (drag direction inconsistent, horizontal X/Y not separately invertible, flinching on drag). Replaced with **`flutter_globe_3d`** v2.2.5 (GPU fragment shader, smoother gestures) — confirmed clean rotation on Fold 5. ADR-010 amended in DECISIONS.md.
- Implementation notes (iter 12):
  - Procedural texture: dark navy ocean + mid-tan continent ovals, generated at app start via Canvas → PNG → MemoryImage (no asset bundle needed for spike).
  - Light follows camera: controller listener inverts `offset → (lat, lng)` and pushes `setFixedLightCoordinates` every frame change, so the lit hemisphere always faces the user — eliminates the dark terminator stripe that `realTime` / `followCamera` modes leave.
  - Device-relative size: square canvas locked to `min(width, height)` so the globe stays a consistent visual proportion across folded portrait, unfolded near-square, tablets, and landscape.
  - Viewport-change reset: when canvas dimensions change (fold/unfold), the controller's zoom + camera focus are reset post-frame and the Earth3D widget is recreated via `ValueKey(canvasSide)`.
  - 8s auto-rotate pause on touch (default 1s was too eager — user couldn't browse).
- Known limitation: the package's pin tap-down propagates to the underlying gesture handler so a tap also rotates the globe slightly. F3.3 will wrap pins in a HitTestBehavior wall before drill-down.
- SRS refs: srs/05-ui-design.md (home), srs/06-geo-logic.md (rendering stack)

### F3.2 — Render visited countries onto globe texture
- [ ] Status: pending
- Depends on: F3.1, F2.5
- Acceptance:
  - At app start, Flutter Canvas rasterizes Natural Earth country polygons → user's visited set → fill colors → PNG
  - PNG fed to globe widget as surface texture
  - Visited tint distinct from unvisited
  - Re-rasters when visited set changes (new post)
- SRS refs: srs/06-geo-logic.md (coloring)

### F3.3 — Country tap → 2D MapLibre detail screen (Hero/fade)
- [ ] Status: pending
- Depends on: F3.1
- Acceptance:
  - Country tap on globe → ~400ms Hero/fade transition → `CountryMapScreen`
  - Detail screen is full-screen `maplibre_gl` map, camera bounded to the tapped country
  - Style JSON matches globe color tokens (no visual identity break)
  - Back button returns to globe with reverse transition
- SRS refs: srs/01-functional.md (home), srs/06-geo-logic.md (rendering stack)

### F3.4 — Pins on the 2D country detail map
- [ ] Status: pending
- Depends on: F3.3, F2.5
- Acceptance:
  - Posts in the tapped country loaded from API
  - GeoJSON source with clustering
  - Custom pin markers with photo thumbnails
- SRS refs: srs/05-ui-design.md#map-pins

### F3.5 — Country + depth coloring (both globe and 2D)
- [ ] Status: pending
- Depends on: F3.2, F3.4
- Acceptance:
  - 5 depth levels per srs/06-geo-logic.md (visit count thresholds)
  - Globe: deeper tint baked into texture per country
  - 2D country view: matching fill via MapLibre layer filter
  - Darker = more visited
- SRS refs: srs/06-geo-logic.md (depth coloring)

### F3.6 — Tap pin → photo preview sheet
- [ ] Status: pending
- Depends on: F3.4
- Acceptance:
  - Tapping cluster opens expanded view
  - Tapping single pin opens photo sheet
  - Sheet shows caption, location, date
- SRS refs: srs/01-functional.md (home)

---

## F4 — Albums

### F4.1 — Auto-trip grouping
- [ ] Status: pending
- Depends on: F2.5
- Acceptance:
  - Server-side date + GPS clustering
  - Creates trip records automatically
  - Heuristic: posts within 48h and <500km = same trip
- SRS refs: srs/02-data-model.md#trips

### F4.2 — Trip album list screen
- [ ] Status: pending
- Depends on: F4.1
- Acceptance:
  - List of user's trips
  - Cover image, title, date range, post count
  - Tap opens album detail
- SRS refs: srs/01-functional.md#albums

### F4.3 — Country album view
- [ ] Status: pending
- Depends on: F4.1
- Acceptance:
  - Filter posts by country_code
  - Same layout as trip album
- SRS refs: srs/01-functional.md#albums

### F4.4 — Album grid masonry layout
- [ ] Status: pending
- Depends on: F4.2
- Acceptance:
  - Masonry grid (staggered heights)
  - Responsive columns (2-3 based on screen width)
  - Smooth scrolling
- SRS refs: srs/05-ui-design.md#masonry

---

## F5 — Profile

### F5.1 — Personal world map embed
- [ ] Status: pending
- Depends on: F3.4
- Acceptance:
  - Mini-map version of F3
  - Shows user's visited countries
  - Read-only (no zoom/pan or limited)
- SRS refs: srs/01-functional.md#profile

### F5.2 — Stats card
- [ ] Status: pending
- Depends on: F5.1
- Acceptance:
  - Countries / cities / posts / stickers counts
  - Calculated server-side
- SRS refs: srs/02-data-model.md#stats

### F5.3 — Travel DNA classification
- [ ] Status: pending
- Depends on: F5.2
- Acceptance:
  - Rule-based classification (per srs/06-geo-logic.md)
  - One of: City Explorer, Nature Seeker, Beach Chaser, etc.
- SRS refs: srs/06-geo-logic.md#travel-dna

### F5.4 — Per-post privacy toggle
- [ ] Status: pending
- Depends on: F2.5
- Acceptance:
  - Toggle: public / followers / private
  - Respected in feed/profile
  - RLS enforced
- SRS refs: srs/04-nfr.md#privacy

---

## F6 — Sharing

### F6.1 — Shareable profile URL
- [ ] Status: pending
- Depends on: F5.1
- Acceptance:
  - Deep-link scheme: `iter://profile/<user_id>`
  - Universal link domain: `iter.app/u/<username>`
  - Share sheet opens
- SRS refs: srs/01-functional.md#sharing

### F6.2 — Public profile read endpoint
- [ ] Status: pending
- Depends on: F6.1
- Acceptance:
  - `GET /users/:id/public` endpoint
  - RLS-aware (respects per-post privacy)
  - No auth required
- SRS refs: srs/03-api.md#public-profile

### F6.3 — Web preview (Flutter Web build)
- [ ] Status: pending
- Depends on: F6.2
- Acceptance:
  - Flutter Web build of profile view only
  - Deployed to Vercel
  - Opens via universal link on desktop
- SRS refs: srs/01-functional.md#sharing

---

## F7 — Discover (basic)

### F7.1 — Public feed endpoint
- [ ] Status: pending
- Depends on: F1.3
- Acceptance:
  - `GET /feed` returns recent public posts
  - Paginated (cursor-based)
  - No personalization yet
- SRS refs: srs/01-functional.md#discover

### F7.2 — Reactions
- [ ] Status: pending
- Depends on: F7.1
- Acceptance:
  - Heart / Want-to-Go / Been-There-Too buttons
  - API endpoints: POST/DELETE /reactions
  - Optimistic UI updates
- SRS refs: srs/03-api.md#reactions

### F7.3 — Report/block
- [ ] Status: pending
- Depends on: F7.1
- Acceptance:
  - Report writes to DB (no triage UI in MVP)
  - Block hides content from feed/profile
  - Block list propagates
- SRS refs: srs/04-nfr.md#safety

---

## F8 — Stickers (Common only)

### F8.1 — Sticker catalog seed
- [ ] Status: pending
- Depends on: F0.3
- Acceptance:
  - Top ~50 countries + major landmarks
  - `stickers` table seeded
- SRS refs: srs/02-data-model.md#stickers

### F8.2 — Auto-grant on first post in country
- [ ] Status: pending
- Depends on: F8.1, F2.5
- Acceptance:
  - Server checks if user has country sticker
  - Grants if not, creates `stickers_earned` record
- SRS refs: srs/02-data-model.md#stickers-earned

### F8.3 — Sticker shelf on profile
- [ ] Status: pending
- Depends on: F8.2
- Acceptance:
  - Horizontal scroll shelf
  - Shows earned stickers
  - Badge count for locked
- SRS refs: srs/05-ui-design.md#stickers

---

## F9 — Journey Line (stretch)

### F9.1 — Time-ordered trip connection
- [ ] Status: pending
- Depends on: F4.1
- Acceptance:
  - Posts in trip ordered by taken_at
  - Consecutive posts connected
- SRS refs: srs/06-geo-logic.md#journey-line

### F9.2 — Flight-arc vs ground-route render
- [ ] Status: pending
- Depends on: F9.1
- Acceptance:
  - Flight arc: distance >300km AND Δt <6h
  - Ground route: otherwise
- SRS refs: srs/06-geo-logic.md#journey-line

### F9.3 — Manual segment-type override
- [ ] Status: pending
- Depends on: F9.2
- Acceptance:
  - User can change flight ↔ ground
  - Override persisted
- SRS refs: srs/06-geo-logic.md#journey-line

---

## F10 — Wishlist

### F10.1 — Add to wishlist
- [ ] Status: pending
- Depends on: F3.1
- Acceptance:
  - Long-press map country → "Want to Go"
  - API: POST/DELETE /wishlist
- SRS refs: srs/01-functional.md#wishlist

### F10.2 — Wishlist overlay on map
- [ ] Status: pending
- Depends on: F10.1
- Acceptance:
  - Distinct visual style (outline or different color)
  - Toggle show/hide
- SRS refs: srs/05-ui-design.md#wishlist

---

## F11 — Safety & Privacy Hardening

### F11.1 — Block list propagation
- [ ] Status: pending
- Depends on: F7.3
- Acceptance:
  - Blocked users hidden from feed
  - Blocked users can't access profile
  - Server-side enforcement
- SRS refs: srs/04-nfr.md#safety

### F11.2 — Report queue
- [ ] Status: pending
- Depends on: F7.3
- Acceptance:
  - Reports write to DB
  - No triage UI in MVP
  - Admin endpoint for export
- SRS refs: srs/04-nfr.md#safety

### F11.3 — Soft-delete posts
- [ ] Status: pending
- Depends on: F2.5
- Acceptance:
  - `DELETE /posts/:id` soft-deletes
  - Hidden from map/feeds
  - Recoverable within 30 days
- SRS refs: srs/02-data-model.md#posts

---

## Definition of Done (MVP)

- F0–F8 all `[x] done`
- No entries in `BLOCKERS.md`
- CI green on `main`
- Manual smoke test: sign in → upload 3 GPS photos → see map colored → share profile link
