-- Schema version 12: AI-app edits waiting for the owner's approval (additive).
-- An AI app connected over MCP proposes a business-profile or knowledge-base
-- change; it reaches customers only after the owner approves it on /admin.
-- One row per target: the profile, or one document key. A newer proposal for
-- the same target merges into (profile) or replaces (document) the row and
-- bumps version, so an approval always names the version the owner saw.
SET LOCAL lock_timeout = '5s';

CREATE TABLE IF NOT EXISTS ai_pending_changes (
    id         BIGSERIAL   PRIMARY KEY,
    account_id BIGINT      NOT NULL,
    kind       TEXT        NOT NULL CHECK (kind IN ('profile', 'document')),
    target     TEXT        NOT NULL,   -- 'profile', or the document key
    proposed   JSONB       NOT NULL,
    actor      TEXT        NOT NULL,   -- the AI app's name
    token_id   BIGINT,
    version    INT         NOT NULL DEFAULT 1,
    at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (account_id, kind, target)
);

ALTER TABLE ai_pending_changes ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON ai_pending_changes FROM anon;
        REVOKE ALL ON SEQUENCE ai_pending_changes_id_seq FROM anon;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE ALL ON ai_pending_changes FROM authenticated;
        REVOKE ALL ON SEQUENCE ai_pending_changes_id_seq FROM authenticated;
    END IF;
END $$;
