-- =============================================================================
-- ITER MVP — Initial Migration
-- =============================================================================
-- Feature:  F0.3 (Supabase setup / schema bootstrap)
-- Date:     2026-05-15
-- Source:   srs/02-data-model.md (lines 7–62, Core Tables only)
-- Scope:    Initial migration. Creates the 4 core tables (users, trips, posts,
--           countries_visited) required for the MVP map-first experience.
--           Later features (F4 wishlists, F7 stickers, F8 journey_lines,
--           F10 follows/reactions, F11 reports/blocks) live in subsequent
--           migrations — YAGNI.
-- Notes:    - Targets Postgres 15+ (Supabase).
--           - This `users` table is our own profile table; it is intentionally
--             NOT linked to Supabase's `auth.users` schema. Linkage (e.g. an
--             `auth_user_id UUID` column) will be introduced in F1.x when auth
--             wiring lands.
--           - RLS is enabled on every table, but no CREATE POLICY statements
--             are executed yet — `auth.uid()` requires the auth wiring above.
--             Policy intents are recorded as stub comments for F1.x.
-- =============================================================================

-- Required for gen_random_uuid().
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------------------------
-- Shared trigger function: bumps updated_at on UPDATE.
-- Used by `users` and `countries_visited` (the two tables that carry an
-- updated_at column per the SRS).
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- =============================================================================
-- users — application-level profile table (not Supabase auth.users)
-- =============================================================================
CREATE TABLE users (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username          TEXT UNIQUE NOT NULL,
    email             TEXT UNIQUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    apple_id          TEXT,
    google_id         TEXT,
    profile_photo_url TEXT,
    bio               TEXT
);

CREATE TRIGGER trg_users_set_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- RLS policy stubs (to be implemented in F1.x once auth.uid() is wired):
-- POLICY: users_select_own           — authenticated user can SELECT their own row (id = auth.uid())
-- POLICY: users_select_public        — any authenticated user can SELECT public profile columns of other users
-- POLICY: users_update_own           — authenticated user can UPDATE only their own row
-- POLICY: users_insert_self          — INSERT restricted to id = auth.uid() (profile bootstrap)


-- =============================================================================
-- trips — must be created BEFORE posts, because posts.trip_id references it.
-- =============================================================================
CREATE TABLE trips (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- FK rationale: a trip is owned by exactly one user; when the user is
    -- deleted, their trips have no meaning and should be removed too.
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title      TEXT,
    started_at TIMESTAMPTZ,
    ended_at   TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trips_user_id ON trips(user_id);

ALTER TABLE trips ENABLE ROW LEVEL SECURITY;

-- RLS policy stubs (F1.x):
-- POLICY: trips_select_own           — authenticated user can SELECT only their own trips (user_id = auth.uid())
-- POLICY: trips_insert_own           — INSERT restricted to user_id = auth.uid()
-- POLICY: trips_update_own           — UPDATE restricted to user_id = auth.uid()
-- POLICY: trips_delete_own           — DELETE restricted to user_id = auth.uid()


-- =============================================================================
-- posts — references both users and trips, so it comes after both.
-- =============================================================================
CREATE TABLE posts (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- FK rationale: a post belongs to its author; deleting the author removes
    -- their posts (consistent with profile deletion semantics for MVP).
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    photo_url    TEXT NOT NULL,
    caption      TEXT,
    lat          DOUBLE PRECISION NOT NULL,
    lng          DOUBLE PRECISION NOT NULL,
    taken_at     TIMESTAMPTZ NOT NULL,
    country_code TEXT NOT NULL,
    city_name    TEXT,
    -- FK rationale: a post may optionally belong to a trip. If the trip is
    -- deleted we keep the post but null the linkage (trips are organizational
    -- grouping, not ownership). Hence ON DELETE SET NULL, not CASCADE.
    trip_id      UUID REFERENCES trips(id) ON DELETE SET NULL,
    privacy      TEXT NOT NULL DEFAULT 'public'
                 CHECK (privacy IN ('public', 'followers', 'private')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Per SRS: indexes on user_id, trip_id, country_code, and the (lat, lng) pair
-- for bounding-box / map-viewport queries. Created explicitly (Postgres does
-- not auto-create indexes for foreign keys).
CREATE INDEX idx_posts_user_id      ON posts(user_id);
CREATE INDEX idx_posts_trip_id      ON posts(trip_id);
CREATE INDEX idx_posts_country_code ON posts(country_code);
CREATE INDEX idx_posts_lat_lng      ON posts(lat, lng);

ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- RLS policy stubs (F1.x):
-- POLICY: posts_select_own           — authenticated user can SELECT their own posts (user_id = auth.uid())
-- POLICY: posts_select_public        — any authenticated user can SELECT posts where privacy = 'public'
-- POLICY: posts_select_followers     — (future) SELECT where privacy = 'followers' AND viewer follows author
-- POLICY: posts_insert_own           — INSERT restricted to user_id = auth.uid()
-- POLICY: posts_update_own           — UPDATE restricted to user_id = auth.uid()
-- POLICY: posts_delete_own           — DELETE restricted to user_id = auth.uid()


-- =============================================================================
-- countries_visited — per-user aggregate; one row per (user, country).
-- =============================================================================
CREATE TABLE countries_visited (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- FK rationale: the aggregate is meaningless without its owner; delete
    -- it when the user is deleted.
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    country_code      TEXT NOT NULL,
    visit_count       INT NOT NULL DEFAULT 1,
    post_count        INT NOT NULL DEFAULT 0,
    unique_city_count INT NOT NULL DEFAULT 0,
    depth_score       INT NOT NULL DEFAULT 1,
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, country_code)
);

CREATE TRIGGER trg_countries_visited_set_updated_at
BEFORE UPDATE ON countries_visited
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

ALTER TABLE countries_visited ENABLE ROW LEVEL SECURITY;

-- RLS policy stubs (F1.x):
-- POLICY: countries_visited_select_own  — authenticated user can SELECT only their own counts (user_id = auth.uid())
-- POLICY: countries_visited_insert_own  — INSERT restricted to user_id = auth.uid() (usually written by backend service role on post create)
-- POLICY: countries_visited_update_own  — UPDATE restricted to user_id = auth.uid() (service role bypasses RLS)
-- POLICY: countries_visited_delete_own  — DELETE restricted to user_id = auth.uid()

-- =============================================================================
-- End of 0001_init.sql
-- =============================================================================
