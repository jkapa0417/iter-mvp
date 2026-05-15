# ITER MVP — Project Instructions

**ITER** is a map-first travel social app MVP built with:
- **Client**: Flutter (iOS + Android)
- **Backend**: Rust (Axum + sqlx + utoipa)
- **Database**: Postgres via Supabase
- **Maps**: Mapbox (`mapbox_maps_flutter`)

## How This Repo Is Driven

This repository is designed to be developed by an **autonomous Ralph Wiggum Loop**.

To start the loop:
```bash
cd /home/yesulmin/junki.ahn/work/iter
/loop @ralph/PROMPT.md
```

Each loop iteration is a fresh Claude context that:
1. Reads `ralph/STATE.md`, `ralph/FEATURE_BACKLOG.md`, `ralph/DECISIONS.md`, `ralph/BLOCKERS.md`
2. Picks the next incomplete feature (F0–F11)
3. Delegates to `feature-planner` (Opus) to decompose into tasks
4. Executes tasks via specialist sub-agents (flutter-implementor, rust-implementor, geo-specialist, photo-pipeline, test-engineer, reviewer)
5. Updates state via `state-updater` (Haiku)
6. Commits with conventional message
7. Exits — loop fires again

## Hard Rules

- **Never commit secrets**. Supabase keys stay local; use env vars.
- **Always run** `flutter analyze` and `cargo check` before claiming a feature is done.
- **Never edit `srs/*`** from inside a feature iteration. SRS changes require explicit human/planner approval.
- **EXIF spike (F0.4)** must run on real devices before being marked done.
- **iOS GPS limitation** is documented in `srs/07-risks.md` — do not attempt to work around it with `image_picker` camera picks.

## Project Layout

```
iter/
├── CLAUDE.md                    # This file
├── README.md                    # Human-readable intro
├── ralph/                       # Ralph Loop control plane
│   ├── PROMPT.md                # The loop entrypoint
│   ├── STATE.md                 # Current iteration status
│   ├── FEATURE_BACKLOG.md       # Feature checklist (F0–F11)
│   ├── DECISIONS.md             # ADR-style decisions log
│   ├── BLOCKERS.md              # Failed features needing human review
│   └── product-context-ko.md    # Korean product brief
├── srs/                         # Software Requirements Spec (English, modular)
│   ├── 00-overview.md
│   ├── 01-functional.md
│   ├── 02-data-model.md
│   ├── 03-api.md
│   ├── 04-nfr.md
│   ├── 05-ui-design.md
│   ├── 06-geo-logic.md
│   ├── 07-risks.md
│   └── 08-out-of-scope.md
├── .claude/agents/              # Sub-agent definitions
├── app/                         # Flutter app (scaffolded by Ralph F0.1)
├── server/                      # Rust backend (scaffolded by Ralph F0.2)
├── infra/                       # Supabase config + migrations
└── scripts/                     # codegen.sh, dev.sh
```

## MVP Success Criterion

A user can:
1. Sign in (Apple/Google/email)
2. Upload N photos from their camera roll
3. See a personal world map with pins, colored countries, and depth shading
4. Share a public profile link

## If Invoked Outside /loop

Treat this as a normal Flutter + Rust project. The Ralph Loop infrastructure only activates when explicitly invoked via `/loop @ralph/PROMPT.md`.
