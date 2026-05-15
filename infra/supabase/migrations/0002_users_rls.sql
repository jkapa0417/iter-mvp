-- =============================================================================
-- ITER MVP — Migration 0002: users RLS policies
-- =============================================================================
-- Feature:  F1.3 (user profile bootstrap)
-- Date:     2026-05-16
-- Source:   srs/04-nfr.md#privacy, srs/02-data-model.md#users
-- Scope:    Adds Row-Level-Security policies on the `users` table linking
--           profile rows to Supabase's `auth.uid()`.
--
--           Defense-in-depth: the Rust server connects with the regular
--           `postgres` user (via the Session pooler) and BYPASSES RLS by
--           default. App-layer authorization in `auth::require_auth` is the
--           primary gate. These policies protect against direct DB access
--           (Supabase dashboard, future PostgREST, accidental misuse of the
--           anon key from the Flutter client).
--
--           Design choice: `users.id` is the same UUID as `auth.uid()` —
--           there is NO separate `auth_user_id` linkage column. This was
--           the original intent in 0001_init.sql ("POLICY: users_select_own
--           — id = auth.uid()"). When the server bootstraps a profile on
--           first /users/me call, it INSERTs with explicit `id = JWT.sub`.
-- =============================================================================

-- Drop in case of re-application (idempotency for the dev workflow).
DROP POLICY IF EXISTS users_select_own ON users;
DROP POLICY IF EXISTS users_insert_self ON users;
DROP POLICY IF EXISTS users_update_own ON users;

-- A signed-in caller can read their own profile.
-- Public profile view for other users lives in a separate `users_public`
-- VIEW that F5 will add — keeping the base-table policy tight here.
CREATE POLICY users_select_own ON users
    FOR SELECT
    TO authenticated
    USING (id = auth.uid());

-- A signed-in caller can create their own profile row (bootstrap).
-- The WITH CHECK ensures they cannot create a row for someone else.
CREATE POLICY users_insert_self ON users
    FOR INSERT
    TO authenticated
    WITH CHECK (id = auth.uid());

-- A signed-in caller can update their own profile, but not change their id.
CREATE POLICY users_update_own ON users
    FOR UPDATE
    TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid());
