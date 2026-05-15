# SRS 03 — API — ITER MVP

> REST endpoints with method/path/auth/request/response. Source-of-truth for Rust utoipa annotations.

## Base URL
- Dev: `http://localhost:8080`
- Prod: `https://api.iter.app`

## Auth
- All endpoints (except `/health`, `/auth/*`) require valid Supabase JWT
- JWT format: ES256, verified via JWKS from Supabase Auth
- Middleware extracts `user_id` from token claims

## Endpoints

### Health
```
GET /health
→ 200 OK
```

### Users
```
GET /users/me
Auth: required
→ 200 { user_id, username, email, profile_photo_url, bio, created_at }

GET /users/:id/public
Auth: optional
→ 200 { username, profile_photo_url, bio, stats: { countries, cities, posts, stickers }, travel_dna }
```

### Posts
```
POST /posts
Auth: required
Body: { photo_url, caption, lat, lng, taken_at, country_code, city_name?, trip_id?, privacy }
→ 201 { id, user_id, photo_url, caption, lat, lng, taken_at, country_code, created_at }

GET /posts
Auth: required
Query: user_id?, trip_id?, country_code?, limit, cursor
→ 200 { posts: [...], next_cursor }

GET /posts/:id
Auth: optional (public if privacy=public)
→ 200 { post, reactions: { heart_count, want_to_go_count, been_there_too_count } }
```

### Trips
```
GET /trips
Auth: required
→ 200 { trips: [{ id, title, started_at, ended_at, post_count, cover_url }] }

GET /trips/:id/posts
Auth: required
→ 200 { posts: [...] }
```

### Reactions
```
POST /reactions
Auth: required
Body: { post_id, reaction_type } // heart | want_to_go | been_there_too
→ 201 { id }

DELETE /reactions/:id
Auth: required
→ 204
```

### Feed (Discover)
```
GET /feed
Auth: required
Query: limit, cursor
→ 200 { posts: [...], next_cursor }
```

## To Be Expanded
~25 endpoints for MVP. Full spec to be generated during F0.2 (Rust scaffold with utoipa).
