-- Schema version 4: knowledge freshness (additive). Optional validity dates
-- hide a document outside its window; use_count and last_used_at show which
-- documents customers' questions actually reach. Nullable columns and a
-- constant default are metadata-only in Postgres 11+, so no table rewrite.
SET LOCAL lock_timeout = '5s';

ALTER TABLE kb_documents
    ADD COLUMN IF NOT EXISTS valid_from   TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS valid_until  TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS use_count    BIGINT NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_used_at TIMESTAMPTZ;
