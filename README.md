# ITER MVP — Map-First Travel Social App

> Turn your trips into a living world map.

## What Is ITER?

ITER is a **map-first travel social app** where users upload travel photos, GPS auto-extracts to place pins on a world map, countries color-fill based on visits, and users share their personal travel identity via public profile links.

**MVP Goal**: Validate that users want a map-based travel record app.

## Tech Stack

- **Client**: Flutter (iOS + Android)
- **Backend**: Rust (Axum + sqlx + utoipa)
- **Database**: Postgres via Supabase
- **Maps**: Mapbox (`mapbox_maps_flutter`)
- **Auth**: Supabase Auth (Apple + Google + email)

## Quick Start

### Prerequisites

- Flutter 3.24+ (stable channel)
- Rust 1.70+ with `cargo`
- Docker (for local Postgres)
- Supabase project (for Auth + Storage)

### Setup

```bash
# 1. Install dependencies
flutter pub get
cd server && cargo build

# 2. Configure environment
cp .env.example .env
# Edit .env with your Supabase credentials

# 3. Start development environment
./scripts/dev.sh
```

### Manual Steps

```bash
# Start Postgres
cd infra && docker-compose up -d postgres

# Start Rust server
cd server && cargo run

# Start Flutter app
cd app && flutter run
```

## Ralph Wiggum Loop

This repo is designed to be developed by an **autonomous AI loop**. To start:

```bash
cd /home/yesulmin/junki.ahn/work/iter
/loop @ralph/PROMPT.md
```

The loop will:
1. Read `ralph/STATE.md` and `ralph/FEATURE_BACKLOG.md`
2. Pick the next incomplete feature
3. Implement it via specialist sub-agents
4. Run tests
5. Update state
6. Commit
7. Exit and repeat

## Project Structure

```
iter/
├── CLAUDE.md                    # Project instructions
├── ralph/                       # Ralph Loop control plane
│   ├── PROMPT.md                # The loop entrypoint
│   ├── STATE.md                 # Current iteration status
│   ├── FEATURE_BACKLOG.md       # Feature checklist (F0–F11)
│   ├── DECISIONS.md             # Architectural decisions
│   └── BLOCKERS.md              # Failed features
├── srs/                         # Software Requirements Spec
├── .claude/agents/              # Sub-agent definitions
├── app/                         # Flutter app
├── server/                      # Rust backend
└── infra/                       # Supabase + migrations
```

## MVP Success Criterion

A user can:
1. Sign in (Apple/Google/email)
2. Upload 3 photos from camera roll
3. See a personal world map with pins and colored countries
4. Share a public profile link

## Development Status

See `ralph/STATE.md` for current progress.

## Known Limitations (MVP)

- **iOS camera GPS**: Not supported via `image_picker` (Flutter limitation). MVP uses gallery-only + manual location fallback.
- **Stickers**: Common stickers only (Rare/Secret post-MVP)
- **Social**: Basic reactions only (no comments, no Traveler Connect)
- **Discovery**: No personalization algorithm yet

## Contributing

This project is developed by the Ralph Wiggum Loop. Human contributions:
- Review `ralph/BLOCKERS.md` for stuck features
- Check `ralph/DECISIONS.md` for architectural context
- Run `/loop @ralph/PROMPT.md` to continue development

## License

MIT

---

**Built with ❤️ for travelers who want to see their journey on a map.**
