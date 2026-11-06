-- Schema version 3: per-business AI feature switches (additive; constant
-- defaults are metadata-only in Postgres 11+, so no table rewrite).
SET LOCAL lock_timeout = '5s';

ALTER TABLE business_profiles
    ADD COLUMN IF NOT EXISTS voice_enabled    BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS images_enabled   BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS stickers_enabled BOOLEAN NOT NULL DEFAULT false;
