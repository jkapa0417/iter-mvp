# SRS 01 — Functional Requirements — ITER MVP

> Per-screen requirements, user stories, elements, state transitions, edge cases.

## Screens

### Home — World Map
*(User stories, elements, state transitions, edge cases)*
- **User Story**: As a traveler, I want to see all my photos on a world map so I can visualize my journey.
- **Elements**: Full-screen map, pins, country fills, journey lines, zoom/pan, pin cluster expansion
- **State**: Loading → Loaded (with pins) → Error
- **Transitions**: Tap pin → photo sheet; Tap country → country album

### Post — Upload Screen
- **User Story**: As a traveler, I want to upload photos with automatic GPS extraction.
- **Elements**: Photo picker, permission gate (iOS Full Access), GPS preview, manual fallback, caption input
- **State**: Draft → Uploading → Posted
- **Transitions**: Missing GPS → manual picker; Success → map update

### Albums
- **User Story**: As a traveler, I want my photos auto-grouped into trips.
- **Elements**: Trip list, country albums, masonry grid, album detail
- **State**: Loading → Loaded (with albums)
- **Transitions**: Tap album → album detail; Tap photo → photo sheet

### Profile
- **User Story**: As a traveler, I want to see my travel identity summarized.
- **Elements**: Mini-map, stats card, travel DNA, sticker shelf, photo grid, share button
- **State**: Own profile vs. public profile
- **Transitions**: Tap share → share sheet; Tap sticker → sticker detail

### Discover
- **User Story**: As a traveler, I want to discover other travelers' posts.
- **Elements**: Feed cards, reactions (heart/want-to-go/been-there-too), report/block
- **State**: Loading → Loaded (with feed)
- **Transitions**: Tap post → post detail; Tap profile → public profile

## Edge Cases
- **No GPS permission**: Show manual location picker
- **GPS stripped from photo**: Detect and prompt manual selection
- **Offline mode**: Cache map tiles; queue uploads
- **Empty state**: Onboarding prompt to upload first photo

## To Be Expanded
This skeleton will be expanded by the Ralph Loop as features are implemented.
