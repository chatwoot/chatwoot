-- Schema version 10: Chatwoot account and inbox names (additive). Filled from
-- signed webhooks as messages arrive, so the admin pages can offer a list of
-- accounts and inboxes by name instead of asking for their numeric IDs.
SET LOCAL lock_timeout = '5s';

CREATE TABLE IF NOT EXISTS chatwoot_inboxes (
    account_id   BIGINT      NOT NULL CHECK (account_id > 0),
    inbox_id     BIGINT      NOT NULL CHECK (inbox_id > 0),
    account_name TEXT        NOT NULL DEFAULT '' CHECK (char_length(account_name) <= 255),
    inbox_name   TEXT        NOT NULL DEFAULT '' CHECK (char_length(inbox_name) <= 255),
    seen_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (account_id, inbox_id)
);

ALTER TABLE chatwoot_inboxes ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON chatwoot_inboxes FROM anon;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE ALL ON chatwoot_inboxes FROM authenticated;
    END IF;
END $$;
