-- Schema version 5: source keys, an audit trail and MCP access tokens
-- (additive). source_key lets an outside source (an AI tool through MCP, a
-- sheet row, a doc, a web page) update the same document again by its own
-- ID. kb_audit keeps a copy of a document before every change made through
-- MCP, so it can be restored. mcp_tokens stores only SHA-256 hashes.
SET LOCAL lock_timeout = '5s';

ALTER TABLE kb_documents ADD COLUMN IF NOT EXISTS source_key TEXT;
-- Same rule as Document.Validate: no empty key, no whitespace, at most 500 characters.
ALTER TABLE kb_documents DROP CONSTRAINT IF EXISTS kb_documents_source_key_check;
ALTER TABLE kb_documents ADD CONSTRAINT kb_documents_source_key_check
    CHECK (source_key IS NULL OR (source_key <> '' AND char_length(source_key) <= 500 AND source_key !~ '[[:space:]]'));
CREATE UNIQUE INDEX IF NOT EXISTS kb_documents_source_key_idx
    ON kb_documents (account_id, source_key) WHERE source_key IS NOT NULL;

CREATE TABLE IF NOT EXISTS kb_audit (
    id          BIGSERIAL   PRIMARY KEY,
    account_id  BIGINT      NOT NULL,
    document_id BIGINT,                 -- the document as it was; it may be gone now
    source_key  TEXT,
    action      TEXT        NOT NULL CHECK (action IN ('create', 'update', 'delete')),
    actor       TEXT        NOT NULL,   -- "mcp:<token name>"
    token_id    BIGINT,                 -- the MCP token that made the change
    before      JSONB,                  -- title, content, kind, inbox, dates before the change
    at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS kb_audit_account_idx ON kb_audit (account_id, at DESC);

CREATE TABLE IF NOT EXISTS mcp_tokens (
    id           BIGSERIAL   PRIMARY KEY,
    account_id   BIGINT      NOT NULL CHECK (account_id > 0),
    name         TEXT        NOT NULL,
    can_write    BOOLEAN     NOT NULL DEFAULT false,
    token_hash   TEXT        NOT NULL UNIQUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_used_at TIMESTAMPTZ,
    expires_at   TIMESTAMPTZ,           -- NULL = never
    revoked_at   TIMESTAMPTZ
);

-- Supabase exposes public tables through its Data API: keep these private.
ALTER TABLE kb_audit ENABLE ROW LEVEL SECURITY;
ALTER TABLE mcp_tokens ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON kb_audit, mcp_tokens FROM anon;
        REVOKE ALL ON SEQUENCE kb_audit_id_seq, mcp_tokens_id_seq FROM anon;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE ALL ON kb_audit, mcp_tokens FROM authenticated;
        REVOKE ALL ON SEQUENCE kb_audit_id_seq, mcp_tokens_id_seq FROM authenticated;
    END IF;
END $$;
