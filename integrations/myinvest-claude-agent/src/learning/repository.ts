import { createHash } from 'node:crypto'
import { tenantKeySchema, type TenantKey } from '../domain.js'
import { redactSupportText, type KnowledgeCandidate } from './extractor.js'

interface QueryResult<Row> {
  rows: Row[]
  rowCount?: number | null
}

interface TransactionClient {
  query<Row extends Record<string, unknown>>(
    text: string,
    values?: readonly unknown[],
  ): Promise<QueryResult<Row>>
  release(): void
}

export interface LearningPool {
  connect(): Promise<TransactionClient>
}

interface InsertedCandidate extends Record<string, unknown> {
  id: string
}

export interface CandidateStoreResult {
  inserted: number
  refreshed: number
}

interface CandidateRow extends Record<string, unknown> {
  id: string
  candidate_key: string
  source_namespace: string
  target_tenant: TenantKey | null
  question_redacted: string
  answer_redacted: string
  content_hash: string
  status: 'quarantined' | 'pending_review' | 'approved' | 'rejected' | 'published'
  published_document_id: string | null
}

function parseActor(actorInput: string): string {
  const actor = actorInput.trim()
  if (!/^[a-z0-9][a-z0-9._@-]{1,127}$/i.test(actor)) throw new Error('Stable reviewer identity required')
  return actor
}

async function transaction<T>(pool: LearningPool, operation: (client: TransactionClient) => Promise<T>): Promise<T> {
  const client = await pool.connect()
  try {
    await client.query('BEGIN')
    const result = await operation(client)
    await client.query('COMMIT')
    return result
  } catch (error) {
    await client.query('ROLLBACK')
    throw error
  } finally {
    client.release()
  }
}

export async function storeExtractedCandidates(
  pool: LearningPool,
  candidates: readonly KnowledgeCandidate[],
): Promise<CandidateStoreResult> {
  return transaction(pool, async (client) => {
    let inserted = 0
    let refreshed = 0
    for (const candidate of candidates) {
      const refreshValues = [
        candidate.candidateKey,
        candidate.previousCandidateKeys,
        candidate.sourcePairDigest,
        candidate.sourceExportId,
        candidate.questionRedacted,
        candidate.answerRedacted,
        candidate.contentHash,
        candidate.redactionCount,
        candidate.riskFlags,
        candidate.redactionVersion,
      ] as const
      const legacyRefresh = candidate.previousCandidateKeys.length === 0
        ? { rows: [] }
        : await client.query<InsertedCandidate>(
          `UPDATE agent_knowledge_candidates candidate
           SET candidate_key = $1, source_pair_digest = $3, source_export_id = $4,
               question_redacted = $5, answer_redacted = $6, content_hash = $7,
               redaction_count = $8, risk_flags = $9, redaction_version = $10,
               updated_at = now()
           WHERE candidate.candidate_key = ANY($2::text[])
             AND candidate.target_tenant IS NULL
             AND candidate.status = 'quarantined'
             AND candidate.published_document_id IS NULL
             AND NOT EXISTS (
               SELECT 1 FROM agent_knowledge_candidates current
               WHERE current.candidate_key = $1
             )
           RETURNING candidate.id`,
          refreshValues,
        )
      if (legacyRefresh.rows[0]) {
        refreshed += 1
        await client.query(
          `INSERT INTO agent_learning_audit_events
             (candidate_id, tenant_key, action, actor, details)
           VALUES ($1, NULL, 'redaction_refreshed', 'hubspot-bundle-extractor', $2)`,
          [legacyRefresh.rows[0].id, { redaction_version: candidate.redactionVersion }],
        )
        continue
      }
      const result = await client.query<InsertedCandidate>(
        `INSERT INTO agent_knowledge_candidates
           (candidate_key, source_namespace, source_export_id, source_conversation_digest,
            target_tenant, question_redacted, answer_redacted, content_hash, redaction_count,
            risk_flags, status, source_pair_digest, redaction_version)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
         ON CONFLICT (candidate_key) DO NOTHING
         RETURNING id`,
        [
          candidate.candidateKey,
          candidate.sourceNamespace,
          candidate.sourceExportId,
          candidate.sourceConversationDigest,
          candidate.targetTenant,
          candidate.questionRedacted,
          candidate.answerRedacted,
          candidate.contentHash,
          candidate.redactionCount,
          candidate.riskFlags,
          candidate.status,
          candidate.sourcePairDigest,
          candidate.redactionVersion,
        ],
      )
      const row = result.rows[0]
      if (row) {
        inserted += 1
        await client.query(
          `INSERT INTO agent_learning_audit_events
             (candidate_id, tenant_key, action, actor, details)
           VALUES ($1, NULL, 'quarantined', 'hubspot-bundle-extractor', $2)`,
          [row.id, { risk_flags: candidate.riskFlags, redaction_count: candidate.redactionCount }],
        )
        continue
      }
      const currentRefresh = await client.query<InsertedCandidate>(
        `UPDATE agent_knowledge_candidates
         SET source_export_id = $2, question_redacted = $3, answer_redacted = $4,
             content_hash = $5, redaction_count = $6, risk_flags = $7,
             source_pair_digest = $8, redaction_version = $9, updated_at = now()
         WHERE candidate_key = $1
           AND target_tenant IS NULL
           AND status = 'quarantined'
           AND published_document_id IS NULL
           AND (redaction_version < $9 OR content_hash <> $5)
         RETURNING id`,
        [
          candidate.candidateKey,
          candidate.sourceExportId,
          candidate.questionRedacted,
          candidate.answerRedacted,
          candidate.contentHash,
          candidate.redactionCount,
          candidate.riskFlags,
          candidate.sourcePairDigest,
          candidate.redactionVersion,
        ],
      )
      if (currentRefresh.rows[0]) {
        refreshed += 1
        await client.query(
          `INSERT INTO agent_learning_audit_events
             (candidate_id, tenant_key, action, actor, details)
           VALUES ($1, NULL, 'redaction_refreshed', 'hubspot-bundle-extractor', $2)`,
          [currentRefresh.rows[0].id, { redaction_version: candidate.redactionVersion }],
        )
      }
    }
    return { inserted, refreshed }
  })
}

export async function refreshReviewedCandidates(
  pool: LearningPool,
  candidates: readonly KnowledgeCandidate[],
): Promise<number> {
  return transaction(pool, async (client) => {
    let refreshed = 0
    for (const candidate of candidates) {
      const identities = [candidate.candidateKey, ...candidate.previousCandidateKeys]
      const reviewed = await client.query<CandidateRow>(
        `SELECT id, candidate_key, source_namespace, target_tenant, question_redacted,
                answer_redacted, content_hash, status, published_document_id
         FROM agent_knowledge_candidates
         WHERE source_namespace = $1
           AND candidate_key = ANY($2::text[])
           AND target_tenant IS NOT NULL
           AND status IN ('pending_review', 'approved', 'published')
           AND redaction_version < $3
         FOR UPDATE`,
        [candidate.sourceNamespace, identities, candidate.redactionVersion],
      )
      for (const row of reviewed.rows) {
        await client.query(
          `UPDATE agent_knowledge_candidates
           SET source_export_id = $2, question_redacted = $3, answer_redacted = $4,
               content_hash = $5, redaction_count = $6, risk_flags = $7,
               redaction_version = $8, status = 'pending_review', reviewed_by = NULL,
               reviewed_at = NULL, published_document_id = NULL, published_at = NULL,
               updated_at = now()
           WHERE id = $1`,
          [
            row.id,
            candidate.sourceExportId,
            candidate.questionRedacted,
            candidate.answerRedacted,
            candidate.contentHash,
            candidate.redactionCount,
            candidate.riskFlags,
            candidate.redactionVersion,
          ],
        )
        if (row.published_document_id && row.target_tenant) {
          await client.query(
            `UPDATE agent_knowledge_documents
             SET active = false, publication_status = 'retired', learning_candidate_id = NULL,
                 updated_at = now()
             WHERE id = $1 AND tenant_key = $2 AND learning_candidate_id = $3`,
            [row.published_document_id, row.target_tenant, row.id],
          )
        }
        await client.query(
          `INSERT INTO agent_learning_audit_events
             (candidate_id, tenant_key, action, actor, details)
           VALUES ($1, $2, 'redaction_refreshed', 'hubspot-redaction-refresh', $3)`,
          [row.id, row.target_tenant, { redaction_version: candidate.redactionVersion, review_required: true }],
        )
        refreshed += 1
      }
    }
    return refreshed
  })
}

export async function sanitizeStaleCandidates(
  pool: LearningPool,
  sourceNamespace: string,
  currentCandidateKeys: readonly string[],
  redactionVersion: number,
): Promise<number> {
  return transaction(pool, async (client) => {
    const stale = await client.query<CandidateRow>(
      `SELECT id, candidate_key, source_namespace, target_tenant, question_redacted,
              answer_redacted, content_hash, status, published_document_id
       FROM agent_knowledge_candidates
       WHERE source_namespace = $1
         AND (redaction_version < $2 OR NOT (candidate_key = ANY($3::text[])))
         AND NOT (
           status = 'rejected' AND redaction_version >= $2
           AND risk_flags @> ARRAY['dlp_refresh_failed']::text[]
         )
       FOR UPDATE`,
      [sourceNamespace, redactionVersion, currentCandidateKeys],
    )
    const placeholder = '[DLP REDACTED: MANUAL REVIEW REQUIRED]'
    const contentHash = createHash('sha256').update(placeholder).digest('hex')
    for (const row of stale.rows) {
      await client.query(
        `UPDATE agent_knowledge_candidates
         SET question_redacted = $2, answer_redacted = $2, content_hash = $3,
             risk_flags = ARRAY['dlp_refresh_failed'], status = 'rejected',
             redaction_version = $4, reviewed_by = NULL, reviewed_at = now(),
             published_document_id = NULL, published_at = NULL, updated_at = now()
         WHERE id = $1`,
        [row.id, placeholder, contentHash, redactionVersion],
      )
      if (row.published_document_id && row.target_tenant) {
        await client.query(
          `UPDATE agent_knowledge_documents
           SET active = false, publication_status = 'retired', learning_candidate_id = NULL,
               updated_at = now()
           WHERE id = $1 AND tenant_key = $2 AND learning_candidate_id = $3`,
          [row.published_document_id, row.target_tenant, row.id],
        )
      }
      await client.query(
        `INSERT INTO agent_learning_audit_events
           (candidate_id, tenant_key, action, actor, details)
         VALUES ($1, $2, 'redaction_refreshed', 'hubspot-redaction-refresh', $3),
                ($1, $2, 'rejected', 'hubspot-redaction-refresh', $4)`,
        [
          row.id,
          row.target_tenant,
          { redaction_version: redactionVersion },
          { reason: 'dlp_refresh_failed_or_source_pair_removed' },
        ],
      )
    }
    return stale.rows.length
  })
}

async function lockedCandidate(client: TransactionClient, candidateId: string): Promise<CandidateRow> {
  if (!/^\d+$/.test(candidateId)) throw new Error('Numeric candidate ID required')
  const result = await client.query<CandidateRow>(
    `SELECT id, candidate_key, source_namespace, target_tenant, question_redacted,
            answer_redacted, content_hash, status, published_document_id
     FROM agent_knowledge_candidates
     WHERE id = $1
     FOR UPDATE`,
    [candidateId],
  )
  if (!result.rows[0]) throw new Error('Candidate not found')
  return result.rows[0]
}

export async function approveCandidate(
  pool: LearningPool,
  candidateId: string,
  tenantInput: string,
  actorInput: string,
): Promise<void> {
  const tenant = tenantKeySchema.parse(tenantInput)
  const actor = parseActor(actorInput)
  await transaction(pool, async (client) => {
    const candidate = await lockedCandidate(client, candidateId)
    if (!['quarantined', 'pending_review'].includes(candidate.status)) {
      throw new Error('Candidate is not awaiting review')
    }
    if (candidate.target_tenant && candidate.target_tenant !== tenant) {
      throw new Error('Candidate belongs to another tenant')
    }
    await client.query(
      `UPDATE agent_knowledge_candidates
       SET target_tenant = $2, status = 'approved', reviewed_by = $3,
           reviewed_at = now(), updated_at = now()
       WHERE id = $1`,
      [candidateId, tenant, actor],
    )
    await client.query(
      `INSERT INTO agent_learning_audit_events
         (candidate_id, tenant_key, action, actor)
       VALUES ($1, $2, 'approved', $3)`,
      [candidateId, tenant, actor],
    )
  })
}

export async function publishCandidate(
  pool: LearningPool,
  candidateId: string,
  actorInput: string,
): Promise<void> {
  const actor = parseActor(actorInput)
  await transaction(pool, async (client) => {
    const candidate = await lockedCandidate(client, candidateId)
    if (candidate.status !== 'approved' || !candidate.target_tenant) {
      throw new Error('Candidate must be explicitly approved and tenant-classified')
    }
    const result = await client.query<{ id: string } & Record<string, unknown>>(
      `INSERT INTO agent_knowledge_documents
         (tenant_key, source_namespace, source_id, title, content, metadata, content_hash,
          publication_status, active, learning_candidate_id)
       VALUES ($1, 'reviewed-hubspot', $2, 'Freigegebene Support-Antwort', $3, $4, $5,
               'published', true, $6)
       RETURNING id`,
      [
        candidate.target_tenant,
        `candidate:${candidate.candidate_key}`,
        `Frage: ${candidate.question_redacted}\n\nAntwort: ${candidate.answer_redacted}`,
        { source: candidate.source_namespace, review: 'human-approved' },
        candidate.content_hash,
        candidate.id,
      ],
    )
    const documentId = result.rows[0]?.id
    if (!documentId) throw new Error('Published document was not created')
    await client.query(
      `UPDATE agent_knowledge_candidates
       SET status = 'published', published_document_id = $2, published_at = now(), updated_at = now()
       WHERE id = $1`,
      [candidate.id, documentId],
    )
    await client.query(
      `INSERT INTO agent_learning_audit_events
         (candidate_id, tenant_key, action, actor, details)
       VALUES ($1, $2, 'published', $3, $4)`,
      [candidate.id, candidate.target_tenant, actor, { document_id: documentId }],
    )
  })
}

export async function rejectCandidate(
  pool: LearningPool,
  candidateId: string,
  actorInput: string,
): Promise<void> {
  const actor = parseActor(actorInput)
  await transaction(pool, async (client) => {
    const candidate = await lockedCandidate(client, candidateId)
    if (!['quarantined', 'pending_review', 'approved', 'published'].includes(candidate.status)) {
      throw new Error('Candidate cannot be rejected from its current state')
    }
    await client.query(
      `UPDATE agent_knowledge_candidates
       SET status = 'rejected', reviewed_by = $2, reviewed_at = now(),
           published_document_id = NULL, published_at = NULL, updated_at = now()
       WHERE id = $1`,
      [candidate.id, actor],
    )
    if (candidate.published_document_id && candidate.target_tenant) {
      await client.query(
        `UPDATE agent_knowledge_documents
         SET active = false, publication_status = 'retired', learning_candidate_id = NULL,
             updated_at = now()
         WHERE id = $1 AND tenant_key = $2 AND learning_candidate_id = $3`,
        [candidate.published_document_id, candidate.target_tenant, candidate.id],
      )
    }
    await client.query(
      `INSERT INTO agent_learning_audit_events
         (candidate_id, tenant_key, action, actor)
       VALUES ($1, $2, 'rejected', $3)`,
      [candidate.id, candidate.target_tenant, actor],
    )
  })
}

export async function recordLearningFeedback(
  pool: LearningPool,
  input: {
    tenantKey: TenantKey
    conversationId: number
    sourceMessageId: number
    candidateId?: string
    rating: 'helpful' | 'unhelpful' | 'human_correction'
    correction?: string
  },
): Promise<boolean> {
  const tenant = tenantKeySchema.parse(input.tenantKey)
  if (!Number.isSafeInteger(input.conversationId) || input.conversationId <= 0) throw new Error('Invalid conversation ID')
  if (!Number.isSafeInteger(input.sourceMessageId) || input.sourceMessageId <= 0) throw new Error('Invalid message ID')
  const correction = input.correction ? redactSupportText(input.correction) : undefined
  if (input.rating === 'human_correction' && (!correction || correction.text.length < 10)) {
    throw new Error('A redacted human correction is required')
  }
  const contentHash = createHash('sha256')
    .update(`${tenant}\0${input.conversationId}\0${input.sourceMessageId}\0${input.rating}\0${correction?.text ?? ''}`)
    .digest('hex')
  return transaction(pool, async (client) => {
    let candidate: CandidateRow | undefined
    if (input.candidateId) {
      candidate = await lockedCandidate(client, input.candidateId)
      if (candidate.target_tenant !== tenant) throw new Error('Feedback candidate belongs to another tenant')
    }
    const result = await client.query<{ id: string } & Record<string, unknown>>(
      `INSERT INTO agent_learning_feedback
         (tenant_key, conversation_id, source_message_id, candidate_id, rating,
          correction_redacted, content_hash)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (tenant_key, source_message_id) DO NOTHING
       RETURNING id`,
      [
        tenant,
        input.conversationId,
        input.sourceMessageId,
        input.candidateId ?? null,
        input.rating,
        correction?.text ?? null,
        contentHash,
      ],
    )
    if (!result.rows[0]) return false
    if (candidate) {
      await client.query(
        `INSERT INTO agent_learning_audit_events
           (candidate_id, tenant_key, action, actor, details)
         VALUES ($1, $2, 'feedback_recorded', 'chatwoot-feedback', $3)`,
        [candidate.id, tenant, { rating: input.rating }],
      )
      if (
        input.rating !== 'helpful' &&
        ['pending_review', 'approved', 'published'].includes(candidate.status)
      ) {
        if (candidate.status === 'published') {
          await client.query(
            `UPDATE agent_knowledge_documents
             SET active = false, publication_status = 'retired', updated_at = now()
             WHERE learning_candidate_id = $1 AND tenant_key = $2`,
            [candidate.id, tenant],
          )
        }
        await client.query(
          `UPDATE agent_knowledge_candidates
           SET status = 'rejected', published_document_id = NULL, published_at = NULL,
               reviewed_at = now(), updated_at = now()
           WHERE id = $1`,
          [candidate.id],
        )
        await client.query(
          `INSERT INTO agent_learning_audit_events
             (candidate_id, tenant_key, action, actor, details)
           VALUES ($1, $2, 'rejected', 'chatwoot-feedback', $3)`,
          [candidate.id, tenant, { reason: 'negative_feedback' }],
        )
      }
    }
    return true
  })
}
