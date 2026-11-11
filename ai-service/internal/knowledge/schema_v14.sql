-- Schema version 14: remember that a private reply was sent (additive).
-- When a person deletes a Facebook comment, ai-service blanks the row and
-- marks it 'removed', which also erased the fact that the page had already
-- sent that person a private reply. The "already answered" notice on
-- /admin/comments then stopped warning the owner about them. replied_at holds
-- only that fact (no text) and is kept when the row is blanked; the row is
-- still deleted with the others 30 days after it arrived.
SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '30s';

ALTER TABLE fb_comments ADD COLUMN IF NOT EXISTS replied_at TIMESTAMPTZ;

-- Rows sent before this change. Rows already blanked cannot be recovered.
UPDATE fb_comments SET replied_at = decided_at
 WHERE status = 'sent' AND replied_at IS NULL AND decided_at IS NOT NULL;
