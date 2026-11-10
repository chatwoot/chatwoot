-- Schema version 13: comments on the business's Facebook Page (additive).
-- Meta's Page feed webhook delivers each new comment; ai-service stores it
-- once (comment_id is unique, so Meta retries and replayed requests add
-- nothing), an LLM scores it and drafts a reply, and the owner sends one
-- private Messenger reply or dismisses it on /admin/comments. A comment the
-- person deletes on Facebook keeps a blank 'removed' row, so a late retry or
-- a replay cannot bring it back. Rows are deleted 30 days after they arrive
-- (they hold people's names and words).
SET LOCAL lock_timeout = '5s';

CREATE TABLE IF NOT EXISTS fb_comments (
    id          BIGSERIAL   PRIMARY KEY,
    account_id  BIGINT      NOT NULL,
    page_id     TEXT        NOT NULL,
    comment_id  TEXT        NOT NULL UNIQUE,
    post_id     TEXT        NOT NULL DEFAULT '',
    parent_id   TEXT        NOT NULL DEFAULT '',
    from_id     TEXT        NOT NULL,
    from_name   TEXT        NOT NULL DEFAULT '',
    message     TEXT        NOT NULL DEFAULT '',
    created_at  TIMESTAMPTZ NOT NULL,             -- when the person commented
    intent      TEXT        NOT NULL DEFAULT ''
                CHECK (intent IN ('', 'lead', 'question', 'complaint', 'other')),
    reason      TEXT        NOT NULL DEFAULT '',
    draft       TEXT        NOT NULL DEFAULT '',
    status      TEXT        NOT NULL DEFAULT 'new'
                CHECK (status IN ('new', 'waiting', 'ignored', 'sending', 'sent', 'dismissed', 'failed', 'removed')),
    reply       TEXT        NOT NULL DEFAULT '',  -- the text that was sent
    decided_by  TEXT        NOT NULL DEFAULT '',
    decided_at  TIMESTAMPTZ,
    error       TEXT        NOT NULL DEFAULT '',
    version     INT         NOT NULL DEFAULT 1,
    attempts    INT         NOT NULL DEFAULT 0,   -- failed scoring passes
    review      JSONB,                            -- shadow reviewer's answer (never acts)
    review_pass BOOLEAN,                          -- would it send the draft unchanged
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (char_length(comment_id) <= 128 AND char_length(post_id) <= 128 AND char_length(parent_id) <= 128),
    CHECK (char_length(page_id) <= 64 AND char_length(from_id) <= 64 AND char_length(from_name) <= 256),
    CHECK (char_length(message) <= 8000),
    CHECK (char_length(reason) <= 500 AND char_length(draft) <= 2000 AND char_length(reply) <= 2000),
    CHECK (char_length(decided_by) <= 320 AND char_length(error) <= 500),
    CHECK (review IS NULL OR octet_length(review::text) <= 8192)
);

-- The admin queue (waiting, newest first), the history and the scorer's pass.
CREATE INDEX IF NOT EXISTS fb_comments_account_status ON fb_comments (account_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS fb_comments_new ON fb_comments (attempts, received_at) WHERE status = 'new';

ALTER TABLE fb_comments ENABLE ROW LEVEL SECURITY;
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        REVOKE ALL ON fb_comments FROM anon;
        REVOKE ALL ON SEQUENCE fb_comments_id_seq FROM anon;
    END IF;
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
        REVOKE ALL ON fb_comments FROM authenticated;
        REVOKE ALL ON SEQUENCE fb_comments_id_seq FROM authenticated;
    END IF;
END $$;
