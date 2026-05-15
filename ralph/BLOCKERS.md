# Blockers — ITER MVP

> Features that failed 3× and need human review. The Ralph Loop will skip these.

---

## Template

### F<X.Y> — [Feature Name]

**Failed at iteration:** N

**Reason:**
Why did it fail 3×?

**Last error:**
Copy of the last error message or test failure.

**Human review needed:**
What specific decision or intervention is required?

---

### F0.3 — Supabase + env vars setup (partial)

**Failed at iteration:** 3

**Reason:**
Autonomous loop cannot create a Supabase project (requires browser OAuth at supabase.com) or fill `.env` with real credentials. The schema migration and sqlx wiring were pre-staged in iteration 3 to minimize the human handoff.

**Last error:**
No error — work simply requires human action; see README "F0.3 — Human Action Required" section.

**Human review needed:**
Execute the 6-step handoff in `README.md` (create Supabase project → fill `.env` → `sqlx migrate run --source ../infra/supabase/migrations`). Once `/health` returns `"db":"connected"`, flip F0.3 to `[x] done` in the backlog and remove this BLOCKERS entry.

**What's already in place (delivered iteration 3):**
- `infra/supabase/migrations/0001_init.sql` — 4 core tables + RLS + triggers
- `server/src/lib.rs` — `AppState`, `init_db_pool()`, JSON /health
- `server/tests/health.rs` — passes with `db:"unconfigured"`
- `README.md` — handoff steps
- See ADR-002 in `ralph/DECISIONS.md` for the partial-block rationale.

---

### F0.5 — OpenAPI codegen pipeline (partial)

**Failed at iteration:** 4

**Reason:**
Two of four acceptance criteria depend on Flutter SDK + an `app/` directory, neither of which exist (F0.1 in BLOCKERS). Specifically: "openapi-generator creates Dart client in `app/lib/api/`" and "Generated client builds without errors" both require Flutter. The Rust side (server emits spec, `scripts/codegen.sh` runs end-to-end on available toolchain) is complete and tested.

**Last error:**
No error — `scripts/codegen.sh` exits 0 with `[skip] app/ not present (F0.1 blocked)` for the Dart steps. Behavior is intentional graceful degradation.

**Human review needed:**
Unblocks automatically once F0.1 lands. Once Flutter SDK is installed and `app/` is scaffolded, re-run `bash scripts/codegen.sh` to generate the Dart client into `app/lib/api/` via `npx @openapitools/openapi-generator-cli`. No further manual action expected.

**What's already in place (delivered iteration 4):**
- `server/src/lib.rs` — `#[utoipa::path]` on /health, `pub struct ApiDoc` with `#[derive(OpenApi)]`
- `server/src/main.rs` — `--emit-openapi` CLI flag (no clap dep; tracing → stderr)
- `scripts/codegen.sh` — docker-free, npx-based, memory-gated, graceful skips
- `server/tests/openapi_emission_test.rs` — integration test asserting 5 OpenAPI contract points
- ADRs in `ralph/DECISIONS.md` document the partial scope

---
