# Architectural Decisions — ITER MVP

> ADR-style log. Append-only. When a decision is made, add a new entry at the top.

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

