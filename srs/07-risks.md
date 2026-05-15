# SRS 07 — Known Technical Risks — ITER MVP

> Identified risks with mitigations. Critical for loop success.

## iOS GPS via `image_picker` — CRITICAL

### Risk
Flutter's `image_picker` **does not provide GPS metadata** when picking from the **camera** on iOS. This is an unresolved Flutter issue (#142914, #45148, #170205 as of 2025).

### Why
iOS 14+ uses PHPicker for privacy, which doesn't expose GPS to apps. The workaround (native AVFoundation camera) requires a custom platform channel implementation.

### MVP Mitigation
1. **Gallery-only flow**: On iOS, only pick from existing photos (not camera)
2. **Permission gate**: Require "Full Access" photo library permission (not "Add Only")
3. **Manual fallback**: Always provide manual location picker (Nominatim search + tap-to-place)
4. **UX copy**: Explain "Full Access" requirement in onboarding

### Verification
- **F0.4 (EXIF spike)** must test on real iOS device with gallery pick
- Simulator cannot test (PHPicker doesn't work on simulator)

### Post-MVP
- **Custom native camera plugin** using AVFoundation to capture GPS at photo time
- Priority: Phase 2

## HEIC Handling

### Risk
HEIC is iOS default camera format. Some packages don't support EXIF reading from HEIC.

### Mitigation
- Use `exif` package (supports HEIC)
- Fallback: `native_exif` package (iOS/Android native)

### Verification
- Real-device test required in F0.4
- Simulators can't test HEIC (converted to JPEG)

## Privacy — Exact Location

### Risk
Users may not want exact GPS coordinates public.

### Mitigation
- **Default precision**: City-level on public profile
- **Exact location**: Only visible to post owner
- **Toggle**: User can override per post

### Implementation
- Store exact lat/lng in DB
- API returns city-only for public queries
- Check RLS policies respect visibility setting

## Map Tile Source Availability

### Risk
OpenFreeMap is a relatively young infrastructure (launched 2024). If it goes down or rate-limits us, the world map breaks.

### Mitigation
- **Runtime tile-source switch**: env var `MAP_TILE_URL` lets us flip between OpenFreeMap, Stadia Maps, MapTiler without a rebuild.
- **Backup provider**: Stadia Maps free tier (200k req/month) keeps us covered if OpenFreeMap is unreachable; requires API key but issuance is instant.
- **Client-side tile cache**: MapLibre's offline pack/cache reduces repeat loads.
- **Long-term**: self-host OpenMapTiles if usage scales past free tiers (one-time setup cost, then zero marginal cost).

### Why not Mapbox
ADR-005 (in `ralph/DECISIONS.md`) records the swap from Mapbox to MapLibre + OpenFreeMap. Mapbox's free tier of 50k loads/month was a hard cost ceiling for MVP; MapLibre + open tile sources removes that ceiling entirely.

## Timezone Boundary Data Size

### Risk
`tz_world` shapefile is ~10MB. May bloat app.

### Mitigation
- Server-side reverse geocoding (fallback)
- Client-side cache with TTL
- Consider vector tile approach

## Out-of-Scope Risks
- **AI features**: Not in MVP; avoid scope creep
- **Payments**: Not in MVP; use stickers for engagement only
- **Real-time**: Not in MVP; async + polling sufficient
