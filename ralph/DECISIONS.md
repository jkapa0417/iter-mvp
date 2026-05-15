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

