-- Schema version 7: team sign-in for AI apps (additive). With Cloudflare
-- Access in front of the approval page, each person is known by email;
-- team_members says which accounts they may connect apps to and whether
-- with write access. oauth_grants records who approved each app.
SET LOCAL lock_timeout = '5s';

CREATE TABLE IF NOT EXISTS team_members (
    email      TEXT        NOT NULL CHECK (email = lower(email) AND email LIKE '%_@_%'),
    account_id BIGINT      NOT NULL CHECK (account_id > 0),
    can_write  BOOLEAN     NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (email, account_id)
);
CREATE INDEX IF NOT EXISTS team_members_account_idx ON team_members (account_id);

ALTER TABLE oauth_grants ADD COLUMN IF NOT EXISTS approved_by TEXT;
ALTER TABLE oauth_codes ADD COLUMN IF NOT EXISTS approved_by TEXT;
CREATE INDEX IF NOT EXISTS oauth_grants_approver_idx ON oauth_grants (approved_by, account_id) WHERE approved_by IS NOT NULL;

ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON team_members FROM anon;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE ALL ON team_members FROM authenticated;
    END IF;
END $$;
