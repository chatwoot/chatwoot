ALTER TABLE agent_knowledge_candidates
  ADD COLUMN IF NOT EXISTS source_pair_digest text;

ALTER TABLE agent_knowledge_candidates
  ADD COLUMN IF NOT EXISTS redaction_version integer NOT NULL DEFAULT 1
  CHECK (redaction_version >= 1);

CREATE UNIQUE INDEX IF NOT EXISTS agent_knowledge_candidates_source_pair_idx
  ON agent_knowledge_candidates (source_namespace, source_pair_digest)
  WHERE source_pair_digest IS NOT NULL;

ALTER TABLE agent_learning_audit_events
  DROP CONSTRAINT IF EXISTS agent_learning_audit_events_action_check;

ALTER TABLE agent_learning_audit_events
  ADD CONSTRAINT agent_learning_audit_events_action_check
  CHECK (action IN (
    'extracted', 'quarantined', 'approved', 'rejected', 'published',
    'feedback_recorded', 'redaction_refreshed'
  ));
