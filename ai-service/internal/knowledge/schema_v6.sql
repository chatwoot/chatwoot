-- Schema version 6: OAuth for MCP (additive). AI apps such as Claude and
-- ChatGPT register themselves (oauth_clients), the owner approves one
-- account and scope for each (oauth_grants), and every access token in
-- mcp_tokens can belong to a grant, so revoking the grant cuts the app off.
-- Codes and tokens are stored as SHA-256 hashes only.
SET LOCAL lock_timeout = '5s';

CREATE TABLE IF NOT EXISTS oauth_clients (
    client_id     TEXT        PRIMARY KEY,
    client_name   TEXT        NOT NULL,
    redirect_uris TEXT[]      NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_used_at  TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS oauth_codes (
    code_hash      TEXT        PRIMARY KEY,
    client_id      TEXT        NOT NULL,
    redirect_uri   TEXT        NOT NULL,
    code_challenge TEXT        NOT NULL,
    account_id     BIGINT      NOT NULL CHECK (account_id > 0),
    can_write      BOOLEAN     NOT NULL,
    resource       TEXT        NOT NULL,
    expires_at     TIMESTAMPTZ NOT NULL,
    used_at        TIMESTAMPTZ,  -- kept after use: a second use revokes what the first issued
    grant_id       BIGINT
);

CREATE TABLE IF NOT EXISTS oauth_grants (
    id                 BIGSERIAL   PRIMARY KEY,
    account_id         BIGINT      NOT NULL CHECK (account_id > 0),
    client_id          TEXT        NOT NULL,
    client_name        TEXT        NOT NULL,
    can_write          BOOLEAN     NOT NULL,
    refresh_hash       TEXT        NOT NULL UNIQUE,
    prev_refresh_hash  TEXT,        -- the one before; using it again means it leaked
    refresh_expires_at TIMESTAMPTZ NOT NULL,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_used_at       TIMESTAMPTZ,
    revoked_at         TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS oauth_grants_account_idx ON oauth_grants (account_id, created_at DESC);
CREATE INDEX IF NOT EXISTS oauth_grants_prev_idx ON oauth_grants (prev_refresh_hash) WHERE prev_refresh_hash IS NOT NULL;

ALTER TABLE mcp_tokens ADD COLUMN IF NOT EXISTS grant_id BIGINT REFERENCES oauth_grants (id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS mcp_tokens_grant_idx ON mcp_tokens (grant_id) WHERE grant_id IS NOT NULL;

ALTER TABLE oauth_clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE oauth_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE oauth_grants ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON oauth_clients, oauth_codes, oauth_grants FROM anon;
        REVOKE ALL ON SEQUENCE oauth_grants_id_seq FROM anon;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE ALL ON oauth_clients, oauth_codes, oauth_grants FROM authenticated;
        REVOKE ALL ON SEQUENCE oauth_grants_id_seq FROM authenticated;
    END IF;
END $$;
