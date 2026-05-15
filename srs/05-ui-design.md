# SRS 05 — UI Design — ITER MVP

> Design tokens, screen layouts, component inventory.

## Design Tokens

### Colors
- **Primary**: Slate Blue (`#5B7C99`)
- **Accent**: Warm Gold (`#D4A574`)
- **Background**: Off-white (`#F9F9F9`) / Dark mode (`#1A1A1A`)
- **Text**: Dark gray (`#333333`) / Light gray (`#E0E0E0`)

### Typography
- **Headings**: SF Pro / Roboto (Medium, 20-28sp)
- **Body**: SF Pro / Roboto (Regular, 16sp)
- **Captions**: SF Pro / Roboto (Light, 14sp)

### Components
- **Cards**: Frosted glass (`backdrop-filter: blur(10px)`)
- **Borders**: Subtle (`0.5px solid rgba(0,0,0,0.1)`)
- **Shadows**: Soft (`box-shadow: 0 4px 12px rgba(0,0,0,0.08)`)

## Screen Layouts

### Home — World Map
- Full-screen map (no chrome)
- Floating action button (new post)
- Bottom sheet (pin preview)
- Cluster expansion dialog

### Post — Upload
- Photo picker (full-screen)
- Permission gate (iOS Full Access)
- GPS preview + manual fallback
- Caption input + privacy toggle

### Albums
- Trip list (card-based, horizontal scroll)
- Album grid (masonry, 2-3 columns)
- Album detail (full-screen grid)

### Profile
- Mini-map embed (30% screen height)
- Stats card (horizontal flex)
- Sticker shelf (horizontal scroll)
- Photo grid (masonry)

### Discover
- Feed cards (aspect-ratio photo + meta)
- Reaction bar (heart, want-to-go, been-there-too)
- Report/block menu

## Component Inventory
- **Scrapbook photo pin**: Polaroid-style thumbnail + shadow
- **Passport stamp sticker**: Circular badge with country flag
- **Journey line**: Dashed ground / curved flight arc
- **Masonry grid**: Staggered heights, smooth scroll

## To Be Expanded
Full Figma designs to be created during UI implementation phase.
