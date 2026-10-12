-- Apply to the Hermes reporting database, not the Chatwoot database.
-- Additive: existing reporting queries and historic rows remain valid.
BEGIN;
SET LOCAL lock_timeout = '5s';
ALTER TABLE distribution_logs
  ADD COLUMN IF NOT EXISTS event_key text,
  ADD COLUMN IF NOT EXISTS chatwoot_account_id bigint,
  ADD COLUMN IF NOT EXISTS chatwoot_inbox_id bigint,
  ADD COLUMN IF NOT EXISTS chatwoot_conversation_id bigint,
  ADD COLUMN IF NOT EXISTS event_kind text,
  ADD COLUMN IF NOT EXISTS assignment_source text,
  ADD COLUMN IF NOT EXISTS first_customer_message_at timestamptz,
  ADD COLUMN IF NOT EXISTS routing jsonb;
CREATE UNIQUE INDEX IF NOT EXISTS distribution_logs_event_key ON distribution_logs (event_key);
COMMIT;
