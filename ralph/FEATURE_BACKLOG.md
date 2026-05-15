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
- [ ] Status: blocked (partial — schema + sqlx wiring done iter 3; awaiting Supabase credentials)
- Depends on: F0.2
- Acceptance:
  - Supabase project created (env vars configured, not committed)
  - `.env` file created from `.env.example` with real credentials
  - `.env.gitignore` updated to exclude `.env`
  - `sqlx migrate run --dry-run` succeeds against Supabase cloud DB
- SRS refs: srs/02-data-model.md

**Note**: Using Supabase cloud database (no local Postgres needed for WSL environment).

### F0.4 — ⚠️ EXIF SPIKE (iOS + Android devices)
- [ ] Status: pending
- Depends on: F0.1
- Acceptance:
  - Given a JPEG/HEIC picked from gallery on iOS device with "Full Access" permission
  - And a JPEG picked from gallery on Android device
  - When app extracts EXIF metadata
  - Then lat/lng/taken_at are successfully extracted and printed to console
  - And HEIC support is verified on iOS real device (simulator not accepted)
  - Result is documented as ADR-001 in DECISIONS.md
- SRS refs: srs/07-risks.md#ios-gps

### F0.5 — OpenAPI codegen pipeline
- [ ] Status: partial (Rust emission iter 4; Dart client gen now unblocked since F0.1 scaffolded app/ in iter 5 — re-run scripts/codegen.sh to complete)
- Depends on: F0.2
- Acceptance:
  - `scripts/codegen.sh` runs end-to-end
  - Rust server emits OpenAPI spec
  - openapi-generator creates Dart client in `app/lib/api/`
  - Generated client builds without errors
- SRS refs: srs/03-api.md

### F0.6 — CI skeleton
- [ ] Status: pending
- Depends on: F0.1, F0.2
- Acceptance:
  - `.github/workflows/ci.yml` created
  - Runs: flutter analyze, flutter test, cargo check, cargo test, sqlx migrate run --dry-run
  - All pass on empty repo
- SRS refs: srs/04-nfr.md

---

## F1 — Auth

### F1.1 — Supabase Auth in Flutter
- [ ] Status: pending
- Depends on: F0.3
- Acceptance:
  - Apple + Google sign-in working
  - Email/password auth working
  - Auth state persists across app restarts
  - Unauthenticated state shows login screen
- SRS refs: srs/01-functional.md#auth

### F1.2 — Rust JWT verification middleware
- [ ] Status: pending
- Depends on: F1.1, F0.2
- Acceptance:
  - ES256/JWKS verification via supabase_jwt crate
  - Middleware rejects invalid tokens
  - Valid tokens pass user_id to handlers
- SRS refs: srs/04-nfr.md#security

### F1.3 — User profile bootstrap
- [ ] Status: pending
- Depends on: F1.2
- Acceptance:
  - `users` table created
  - First login creates user row with default profile
  - `GET /users/me` returns current user profile
- SRS refs: srs/02-data-model.md#users

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

### F3.1 — MapLibre map widget
- [ ] Status: pending
- Depends on: F1.3
- Acceptance:
  - Full-screen `maplibre_gl` map loads
  - Vector tiles served from OpenFreeMap (env var `MAP_TILE_URL` overrideable for Stadia/MapTiler fallback)
  - No API key required for default tile source
  - Zoom/pan gestures work
- SRS refs: srs/01-functional.md#home-screen, srs/06-geo-logic.md#map-rendering-stack

### F3.2 — Render user's posts as pins
- [ ] Status: pending
- Depends on: F3.1, F2.5
- Acceptance:
  - Posts loaded from API
  - GeoJSON source with clustering
  - Custom pin markers with photo thumbnails
- SRS refs: srs/05-ui-design.md#map-pins

### F3.3 — Country fill coloring
- [ ] Status: pending
- Depends on: F3.2
- Acceptance:
  - Visited countries filled
  - Unvisited countries transparent
  - Vector tile filter implementation
- SRS refs: srs/06-geo-logic.md#coloring

### F3.4 — Depth coloring
- [ ] Status: pending
- Depends on: F3.3
- Acceptance:
  - 5 depth levels (per srs/06-geo-logic.md)
  - Darker fill = more visited
- SRS refs: srs/06-geo-logic.md#depth-coloring

### F3.5 — Tap pin → photo preview
- [ ] Status: pending
- Depends on: F3.2
- Acceptance:
  - Tapping cluster opens expanded view
  - Tapping single pin opens photo sheet
  - Sheet shows caption, location, date
- SRS refs: srs/01-functional.md#home-screen

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
