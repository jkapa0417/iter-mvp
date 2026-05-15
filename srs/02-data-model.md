# SRS 02 — Data Model — ITER MVP

> Postgres schema (ERD), table-by-table spec, indexes, RLS policy intent.

## Core Tables

### users
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
username TEXT UNIQUE NOT NULL
email TEXT UNIQUE
created_at TIMESTAMPTZ DEFAULT NOW()
updated_at TIMESTAMPTZ DEFAULT NOW()
apple_id TEXT
google_id TEXT
profile_photo_url TEXT
bio TEXT
-- RLS: Users can read own profile + public profiles
```

### posts
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id UUID REFERENCES users(id)
photo_url TEXT NOT NULL
caption TEXT
lat DOUBLE PRECISION NOT NULL
lng DOUBLE PRECISION NOT NULL
taken_at TIMESTAMPTZ NOT NULL
country_code TEXT NOT NULL
city_name TEXT
trip_id UUID REFERENCES trips(id)
privacy TEXT NOT NULL DEFAULT 'public' -- public/followers/private
created_at TIMESTAMPTZ DEFAULT NOW()
-- Indexes: user_id, trip_id, country_code, (lat, lng)
-- RLS: Users can read own posts + public posts from others
```

### trips
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id UUID REFERENCES users(id)
title TEXT
started_at TIMESTAMPTZ
ended_at TIMESTAMPTZ
created_at TIMESTAMPTZ DEFAULT NOW()
-- RLS: Users can read own trips
```

### countries_visited
```sql
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id UUID REFERENCES users(id)
country_code TEXT NOT NULL
visit_count INT DEFAULT 1
post_count INT DEFAULT 0
unique_city_count INT DEFAULT 0
depth_score INT DEFAULT 1
updated_at TIMESTAMPTZ DEFAULT NOW()
UNIQUE(user_id, country_code)
-- RLS: Users can read own counts
```

## Additional Tables
- `wishlists`: user_id, country_code, place_name, lat, lng
- `stickers`: id, name, type (common/rare/secret), country_code, place_name
- `stickers_earned`: user_id, sticker_id, post_id, earned_at
- `journey_lines`: trip_id, from_post_id, to_post_id, segment_type (flight/ground)
- `user_events`: user_id, event_type, metadata, created_at (for analytics)
- `follows`: follower_id, following_id
- `reactions`: user_id, post_id, reaction_type (heart/want_to go/been there too)
- `reports`: reporter_id, reported_user_id, post_id, reason
- `blocks`: blocker_id, blocked_id

## To Be Expanded
Full schema with indexes and RLS policies to be defined during F0.3 (Supabase setup).
