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

<!-- F0.5 resolved in iter 6 — moved to FEATURE_BACKLOG as [x] done. See ADR-007. -->

---
