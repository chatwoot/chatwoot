-- Schema version 2: one business profile per Chatwoot account (additive).
SET LOCAL lock_timeout = '5s';

CREATE TABLE IF NOT EXISTS business_profiles (
    account_id    BIGINT      PRIMARY KEY CHECK (account_id > 0),
    business_name TEXT        NOT NULL DEFAULT '',
    about         TEXT        NOT NULL DEFAULT '',
    tone          TEXT        NOT NULL DEFAULT '',
    contact       TEXT        NOT NULL DEFAULT '',
    rules         TEXT        NOT NULL DEFAULT '',
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Supabase exposes public tables through its Data API: keep this one private.
ALTER TABLE business_profiles ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON business_profiles FROM anon;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE ALL ON business_profiles FROM authenticated;
    END IF;
END $$;
