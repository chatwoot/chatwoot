-- Schema version 9: website pages kept in sync (additive). Each row is a
-- public page an owner added; the syncer re-checks it on a schedule and
-- updates the knowledge document whose source_key is the page URL.
SET LOCAL lock_timeout = '5s';

CREATE TABLE IF NOT EXISTS web_sources (
    id              BIGSERIAL   PRIMARY KEY,
    account_id      BIGINT      NOT NULL CHECK (account_id > 0),
    url             TEXT        NOT NULL CHECK (url ~ '^https?://' AND char_length(url) <= 500),
    title           TEXT        NOT NULL DEFAULT '',
    interval_hours  INT         NOT NULL DEFAULT 24 CHECK (interval_hours BETWEEN 1 AND 720),
    content_hash    TEXT        NOT NULL DEFAULT '',
    last_status     TEXT        NOT NULL DEFAULT 'new' CHECK (last_status IN ('new', 'ok', 'error', 'gone')),
    last_error      TEXT        NOT NULL DEFAULT '',
    last_checked_at TIMESTAMPTZ,
    last_changed_at TIMESTAMPTZ,
    gone_since      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (account_id, url)
);
CREATE INDEX IF NOT EXISTS web_sources_due_idx ON web_sources (last_checked_at NULLS FIRST);

ALTER TABLE web_sources ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON web_sources FROM anon;
        REVOKE ALL ON SEQUENCE web_sources_id_seq FROM anon;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE ALL ON web_sources FROM authenticated;
        REVOKE ALL ON SEQUENCE web_sources_id_seq FROM authenticated;
    END IF;
END $$;
