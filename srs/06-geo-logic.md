# SRS 06 — Geographic Logic — ITER MVP

> GPS mapping, depth coloring, journey line heuristics.

## GPS → Country/City Mapping

### Strategy
1. **Offline point-in-polygon against Natural Earth boundaries** (primary; fast, no network, no cost)
2. **Online fallback**: Nominatim reverse geocoding (https://nominatim.openstreetmap.org) for edge cases — free, 1 req/s rate limit, must include User-Agent header per their policy

### Data Sources
- Natural Earth country shapes: `ne_50m_admin_0_countries.geojson` (~2 MB; bundled as Flutter asset)
- Timezone boundary shapes (`tz_world_mp.zip`): optional secondary signal for disputed-territory cases
- City lookup: Local `cities1500.txt` from GeoNames

### Map Rendering Stack
- **Tile renderer**: MapLibre GL (`maplibre_gl` Flutter plugin) — Mapbox GL v1 fork, open-source
- **Vector tiles**: OpenFreeMap (https://openfreemap.org) — free, no API key, no rate limit; OpenMapTiles schema
- **Backup tile source**: Stadia Maps free tier (200k requests/month) — switch via runtime env if OpenFreeMap is unreachable

### Mapping Function
```rust
fn gps_to_country(lat: f64, lng: f64) -> Option<String> {
    // 1. Point-in-polygon against natural_earth shapes
    // 2. Fallback to timezone → country mapping
}
```

## Depth Coloring

### Levels (per product brief §17)
| Level | Condition | Color opacity |
|-------|-----------|---------------|
| 1 | post 1+ | 20% |
| 2 | post 3+ OR city 2+ | 40% |
| 3 | post 7+ OR city 4+ | 60% |
| 4 | post 15+ OR city 6+ | 80% |
| 5 | post 30+ OR city 10+ | 100% |

### Calculation Trigger
- Recalculate on post create/delete
- Cache in `countries_visited.depth_score`

## Journey Line

### Heuristic
For consecutive posts in a trip (ordered by `taken_at`):
```
if distance > 300km AND time_diff < 6h:
    segment_type = "flight"
else:
    segment_type = "ground"
```

### User Override
- User can toggle flight ↔ ground per segment
- Override persisted in `journey_lines.segment_type`

## Travel DNA

### Rule-Based Classification
| DNA Type | Condition |
|----------|-----------|
| City Explorer | >60% posts in urban areas |
| Nature Seeker | >60% posts in natural areas |
| Beach Chaser | >40% posts near coast |
| Landmark Collector | >50% posts at landmarks |
| Off the Grid | <10% posts in urban areas |
| Weekend Traveler | Avg trip <3 days |
| Long Trip Traveler | Avg trip >7 days |

### Area Classification
- **Urban**: Population >100K OR within 5km of city center
- **Natural**: Protected area OR population <10K
- **Coastal**: Within 2km of coastline
- **Landmark**: OSM tag `tourism=*`

## To Be Expanded
Full implementation during F3 (World Map) and F9 (Journey Line).
