ALTER TABLE agent_knowledge_documents
  ADD COLUMN IF NOT EXISTS source_namespace text NOT NULL DEFAULT 'approved-manual';

ALTER TABLE agent_knowledge_documents
  ADD COLUMN IF NOT EXISTS publication_status text NOT NULL DEFAULT 'published';

ALTER TABLE agent_knowledge_documents
  ADD COLUMN IF NOT EXISTS active boolean NOT NULL DEFAULT true;

ALTER TABLE agent_knowledge_documents
  ADD COLUMN IF NOT EXISTS ingest_batch_id text;

ALTER TABLE agent_knowledge_documents
  DROP CONSTRAINT IF EXISTS agent_knowledge_documents_publication_status_check;

ALTER TABLE agent_knowledge_documents
  ADD CONSTRAINT agent_knowledge_documents_publication_status_check
  CHECK (publication_status IN ('published', 'retired'));

ALTER TABLE agent_knowledge_documents
  DROP CONSTRAINT IF EXISTS agent_knowledge_documents_tenant_key_source_id_content_hash_key;

CREATE UNIQUE INDEX IF NOT EXISTS agent_knowledge_documents_source_version_idx
  ON agent_knowledge_documents (tenant_key, source_namespace, source_id, content_hash);

CREATE INDEX IF NOT EXISTS agent_knowledge_documents_retrieval_idx
  ON agent_knowledge_documents (tenant_key, publication_status, active);

CREATE TABLE IF NOT EXISTS agent_knowledge_candidates (
  id bigserial PRIMARY KEY,
  candidate_key text NOT NULL UNIQUE,
  source_namespace text NOT NULL,
  source_export_id text NOT NULL,
  source_conversation_digest text NOT NULL,
  target_tenant text CHECK (target_tenant IN ('saas', 'new_academy', 'legacy_academy')),
  question_redacted text NOT NULL,
  answer_redacted text NOT NULL,
  content_hash text NOT NULL,
  redaction_count integer NOT NULL DEFAULT 0 CHECK (redaction_count >= 0),
  risk_flags text[] NOT NULL DEFAULT '{}',
  status text NOT NULL CHECK (status IN ('quarantined', 'pending_review', 'approved', 'rejected', 'published')),
  reviewed_by text,
  reviewed_at timestamptz,
  published_at timestamptz,
  published_document_id bigint UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id, target_tenant)
);

CREATE INDEX IF NOT EXISTS agent_knowledge_candidates_review_idx
  ON agent_knowledge_candidates (status, target_tenant, created_at);

ALTER TABLE agent_knowledge_documents
  ADD COLUMN IF NOT EXISTS learning_candidate_id bigint;

CREATE UNIQUE INDEX IF NOT EXISTS agent_knowledge_documents_learning_candidate_idx
  ON agent_knowledge_documents (learning_candidate_id)
  WHERE learning_candidate_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS agent_knowledge_documents_candidate_binding_idx
  ON agent_knowledge_documents (id, learning_candidate_id, tenant_key);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'agent_knowledge_documents_candidate_tenant_fk'
  ) THEN
    ALTER TABLE agent_knowledge_documents
      ADD CONSTRAINT agent_knowledge_documents_candidate_tenant_fk
      FOREIGN KEY (learning_candidate_id, tenant_key)
      REFERENCES agent_knowledge_candidates (id, target_tenant);
  END IF;
END
$$;

ALTER TABLE agent_knowledge_candidates
  DROP CONSTRAINT IF EXISTS agent_knowledge_candidates_published_document_fk;

ALTER TABLE agent_knowledge_candidates
  ADD CONSTRAINT agent_knowledge_candidates_published_document_fk
  FOREIGN KEY (published_document_id, id, target_tenant)
  REFERENCES agent_knowledge_documents (id, learning_candidate_id, tenant_key);

ALTER TABLE agent_knowledge_candidates
  DROP CONSTRAINT IF EXISTS agent_knowledge_candidates_publication_binding_check;

ALTER TABLE agent_knowledge_candidates
  ADD CONSTRAINT agent_knowledge_candidates_publication_binding_check
  CHECK (
    (status = 'published' AND published_document_id IS NOT NULL AND published_at IS NOT NULL)
    OR (status <> 'published' AND published_document_id IS NULL AND published_at IS NULL)
  );

CREATE TABLE IF NOT EXISTS agent_learning_feedback (
  id bigserial PRIMARY KEY,
  tenant_key text NOT NULL CHECK (tenant_key IN ('saas', 'new_academy', 'legacy_academy')),
  conversation_id bigint NOT NULL,
  source_message_id bigint NOT NULL,
  candidate_id bigint,
  rating text NOT NULL CHECK (rating IN ('helpful', 'unhelpful', 'human_correction')),
  correction_redacted text,
  content_hash text NOT NULL,
  status text NOT NULL DEFAULT 'pending_review' CHECK (status IN ('pending_review', 'reviewed', 'rejected')),
  created_at timestamptz NOT NULL DEFAULT now(),
  reviewed_at timestamptz,
  UNIQUE (tenant_key, source_message_id),
  FOREIGN KEY (candidate_id, tenant_key)
    REFERENCES agent_knowledge_candidates (id, target_tenant)
);

CREATE INDEX IF NOT EXISTS agent_learning_feedback_review_idx
  ON agent_learning_feedback (tenant_key, status, created_at);

CREATE TABLE IF NOT EXISTS agent_learning_audit_events (
  id bigserial PRIMARY KEY,
  candidate_id bigint NOT NULL REFERENCES agent_knowledge_candidates (id),
  tenant_key text CHECK (tenant_key IN ('saas', 'new_academy', 'legacy_academy')),
  action text NOT NULL CHECK (action IN ('extracted', 'quarantined', 'approved', 'rejected', 'published', 'feedback_recorded')),
  actor text NOT NULL,
  details jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'agent_learning_audit_candidate_tenant_fk'
  ) THEN
    ALTER TABLE agent_learning_audit_events
      ADD CONSTRAINT agent_learning_audit_candidate_tenant_fk
      FOREIGN KEY (candidate_id, tenant_key)
      REFERENCES agent_knowledge_candidates (id, target_tenant);
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS agent_learning_audit_candidate_idx
  ON agent_learning_audit_events (candidate_id, created_at);

CREATE OR REPLACE FUNCTION agent_validate_candidate_transition()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = OLD.status THEN
    RETURN NEW;
  END IF;

  IF (OLD.status IN ('quarantined', 'pending_review') AND NEW.status IN ('approved', 'rejected'))
     OR (OLD.status = 'approved' AND NEW.status IN ('published', 'rejected'))
     OR (OLD.status = 'published' AND NEW.status = 'rejected') THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION 'invalid candidate status transition: % -> %', OLD.status, NEW.status;
END;
$$;

DROP TRIGGER IF EXISTS agent_knowledge_candidates_transition_guard ON agent_knowledge_candidates;
CREATE TRIGGER agent_knowledge_candidates_transition_guard
  BEFORE UPDATE OF status ON agent_knowledge_candidates
  FOR EACH ROW EXECUTE FUNCTION agent_validate_candidate_transition();
