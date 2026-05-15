# Architectural Decisions — ITER MVP

> ADR-style log. Append-only. When a decision is made, add a new entry at the top.

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

