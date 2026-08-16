CREATE TABLE IF NOT EXISTS agent_knowledge_documents (
  id bigserial PRIMARY KEY,
  tenant_key text NOT NULL CHECK (tenant_key IN ('saas', 'new_academy', 'legacy_academy')),
  source_id text NOT NULL,
  title text NOT NULL,
  content text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  content_hash text NOT NULL,
  search_vector tsvector GENERATED ALWAYS AS (
    to_tsvector('german', coalesce(title, '') || ' ' || coalesce(content, ''))
  ) STORED,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (tenant_key, source_id, content_hash)
);

CREATE INDEX IF NOT EXISTS agent_knowledge_documents_search_idx
  ON agent_knowledge_documents USING gin (search_vector);

CREATE INDEX IF NOT EXISTS agent_knowledge_documents_tenant_source_idx
  ON agent_knowledge_documents (tenant_key, source_id);

CREATE TABLE IF NOT EXISTS agent_conversation_states (
  tenant_key text NOT NULL CHECK (tenant_key IN ('saas', 'new_academy', 'legacy_academy')),
  conversation_id bigint NOT NULL,
  status text NOT NULL CHECK (status IN ('active', 'handed_off')),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_key, conversation_id)
);

CREATE TABLE IF NOT EXISTS agent_delivery_ledger (
  tenant_key text NOT NULL CHECK (tenant_key IN ('saas', 'new_academy', 'legacy_academy')),
  message_id bigint NOT NULL,
  conversation_id bigint NOT NULL,
  status text NOT NULL CHECK (status IN ('processing', 'sending', 'replied', 'handed_off')),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (tenant_key, message_id)
);

ALTER TABLE agent_delivery_ledger
  DROP CONSTRAINT IF EXISTS agent_delivery_ledger_status_check;
ALTER TABLE agent_delivery_ledger
  ADD CONSTRAINT agent_delivery_ledger_status_check
  CHECK (status IN ('processing', 'sending', 'replied', 'handed_off'));

CREATE INDEX IF NOT EXISTS agent_delivery_ledger_conversation_idx
  ON agent_delivery_ledger (tenant_key, conversation_id);
