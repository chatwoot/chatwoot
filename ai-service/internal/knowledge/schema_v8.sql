-- Schema version 8: a log of changes made on the admin pages (additive):
-- tokens, team, connected apps, knowledge edits (with the old text), the
-- business profile and provider settings (hosts and models, never keys).
-- MCP changes stay in kb_audit; the admin home shows both.
SET LOCAL lock_timeout = '5s';

CREATE TABLE IF NOT EXISTS admin_events (
    id         BIGSERIAL   PRIMARY KEY,
    account_id BIGINT,                 -- NULL for service-wide settings
    actor      TEXT        NOT NULL,   -- owner email, or "admin password"
    action     TEXT        NOT NULL,
    summary    TEXT        NOT NULL,
    before     JSONB,
    at         TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS admin_events_account_idx ON admin_events (account_id, at DESC);

ALTER TABLE admin_events ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON admin_events FROM anon;
        REVOKE ALL ON SEQUENCE admin_events_id_seq FROM anon;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE ALL ON admin_events FROM authenticated;
        REVOKE ALL ON SEQUENCE admin_events_id_seq FROM authenticated;
    END IF;
END $$;
