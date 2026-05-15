# SRS 00 — Overview — ITER MVP

## Product Vision (5 lines)

ITER is a **map-first travel social app** where users upload travel photos, GPS auto-extracts to place pins on a world map, countries color-fill based on visits, and users share their personal travel identity via public profile links.

**One-sentence pitch**: Turn your trips into a living world map.

## MVP Success Criterion (Single Sentence)

A user can sign in, upload 3 photos from their camera roll, see a personal world map with pins and colored countries, and share a public profile link.

## Scope Boundaries

### In-Scope (MVP)
- Photo upload with GPS extraction (gallery-only on iOS due to Flutter limitation)
- World map with photo pins, country coloring, depth shading
- Auto-grouped trip albums
- Public profile with stats and travel DNA
- Basic social feed (heart, want-to-go, been-there-too)
- Common stickers (auto-granted on first post in country)
- Public profile sharing via link

### Out-of-Scope (Post-MVP)
- AI travel planner
- Flight/hotel booking
- Payments
- Rare/Secret stickers
- Traveler Connect
- Comments
- Real-time messaging
- Shared trip albums
- Photo book printing
- B2B data dashboards

## Glossary

| Term | Definition |
|------|------------|
| **World Map** | The home screen showing a full-screen map with user's travel data |
| **Pin** | A marker on the map representing a photo post |
| **Country Coloring** | Visual fill of visited countries on the map |
| **Depth Coloring** | Darker fill = more visits/posts in a country (5 levels) |
| **Journey Line** | Lines connecting posts within a trip (flight arcs vs ground routes) |
| **Travel DNA** | Rule-based user classification (e.g., "City Explorer") |
| **Sticker** | Location-based collectible badge (Common/Rare/Secret; MVP: Common only) |
| **Trip** | Auto-grouped set of posts within 48h and <500km |

## References

- Product brief (Korean): `ralph/product-context-ko.md`
- Feature backlog: `ralph/FEATURE_BACKLOG.md`
- Technical decisions: `ralph/DECISIONS.md`
