# Ralph Wiggum Loop — ITER MVP

You are a single iteration of the Ralph Wiggum Loop. Your context is fresh. Follow these steps exactly.

## Step 1 — Read State

Read these files **in order**:
1. `srs/00-overview.md` — Product vision + scope
2. `ralph/STATE.md` — Current iteration + last completed feature
3. `ralph/FEATURE_BACKLOG.md` — Feature checklist (F0–F11)
4. `ralph/DECISIONS.md` — Architectural decisions made so far
5. `ralph/BLOCKERS.md` — Features that failed 3× (SKIP these)

Stop reading early if `STATE.md` already tells you what to do.

## Step 2 — Pick Next Feature

From `FEATURE_BACKLOG.md`, find the **lowest-numbered feature** that is `[ ] pending` and NOT in `BLOCKERS.md`.

If all features are `[x] done`:
- Exit cleanly with message: "MVP backlog drained — human review required."

If a feature is in `BLOCKERS.md`:
- Skip it and pick the next one.

## Step 3 — Plan via feature-planner

Invoke the `feature-planner` sub-agent (Opus) with:
- The feature ID (e.g., "F2.2")
- Relevant SRS section pointers
- Current `DECISIONS.md` content

The `feature-planner` will return a task plan (≤8 tasks).

**Sub-agent invocation template:**
```
@agent feature-planner

Plan feature: <feature-id>

Context from SRS:
- <srs-section-1>
- <srs-section-2>

Current decisions (from DECISIONS.md):
<paste relevant decisions>

Return a task plan with ≤8 tasks. Each task should have:
- Task ID
- Description
- Target file(s)
- Dependencies
```

## Step 4 — Execute Tasks

For each task in the plan, delegate to the appropriate specialist sub-agent:

| Task Type | Sub-Agent | Model |
|-----------|-----------|-------|
| Flutter UI/logic | flutter-implementor | Sonnet |
| Rust endpoint/handler | rust-implementor | Sonnet |
| DB schema/migration | schema-architect | Opus |
| Mapbox/geo logic | geo-specialist | Sonnet |
| Photo/EXIF/upload | photo-pipeline | Sonnet |

**Execute in parallel where possible** (tasks with no dependencies).

## Step 5 — Test

Invoke `test-engineer` (Sonnet) to:
1. Run `flutter test` in `app/`
2. Run `cargo test` in `server/`
3. If tests fail, attempt ONE fix pass
4. If still failing, append feature to `BLOCKERS.md` and exit

## Step 6 — Review

Invoke `reviewer` (Sonnet) to check:
- API contract matches `srs/03-api.md`
- RLS policies respected (server uses service-role correctly)
- Flutter ↔ Rust types sync (codegen pipeline intact)
- SRS adherence (no scope drift)

## Step 7 — Update State

Invoke `state-updater` (Haiku) to:
1. Mark feature `[x] done` in `FEATURE_BACKLOG.md`
2. Append progress line to `STATE.md`
3. Append any decisions to `DECISIONS.md`
4. Trim `STATE.md` to last 20 entries

## Step 8 — Commit

Commit changes with conventional message:
```
feat(F<x.y>): <summary>

<optional body>
```

## Step 9 — Exit

Exit cleanly. The loop will fire again with fresh context.

---

## Do NOT Deviate

- Do NOT edit `srs/*` files.
- Do NOT skip the test step.
- Do NOT proceed if tests fail.
- Do NOT mark F0.4 (EXIF spike) as done without real-device verification.
- Do NOT attempt to fix iOS GPS via `image_picker` camera — it's a known Flutter limitation (see `srs/07-risks.md`).

---

## Loop Termination Conditions

Exit immediately if:
1. All features F0–F11 are `[x] done`
2. A feature enters `BLOCKERS.md`
3. `STATE.md` iteration count exceeds 50 (safety cap)

In each case, leave a clear summary in `STATE.md`.
