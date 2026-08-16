import { describe, expect, it, vi } from 'vitest'
import {
  approveCandidate,
  publishCandidate,
  recordLearningFeedback,
  refreshReviewedCandidates,
  rejectCandidate,
  sanitizeStaleCandidates,
  storeExtractedCandidates,
} from '../src/learning/repository.js'
import type { KnowledgeCandidate } from '../src/learning/extractor.js'

const candidate: KnowledgeCandidate = {
  candidateKey: 'a'.repeat(64),
  previousCandidateKeys: ['d'.repeat(64)],
  sourcePairDigest: 'e'.repeat(64),
  sourceNamespace: 'hubspot-conversations-v3',
  sourceExportId: 'export-1',
  sourceConversationDigest: 'b'.repeat(64),
  targetTenant: null,
  questionRedacted: 'Wie funktioniert das Onboarding?',
  answerRedacted: 'Öffne den Bereich Einstellungen.',
  contentHash: 'c'.repeat(64),
  redactionCount: 0,
  riskFlags: ['unclassified_hubspot_history'],
  status: 'quarantined',
  redactionVersion: 3,
}

function fakePool(handler: (sql: string, values?: readonly unknown[]) => { rows: unknown[] }) {
  const query = vi.fn(async (sql: string, values?: readonly unknown[]) => handler(sql, values))
  return { pool: { connect: vi.fn().mockResolvedValue({ query, release: vi.fn() }) }, query }
}

describe('knowledge learning repository', () => {
  it('stores candidates idempotently without publishing', async () => {
    let inserted = false
    const database = fakePool((sql) => {
      if (sql.includes('INSERT INTO agent_knowledge_candidates')) {
        if (inserted) return { rows: [] }
        inserted = true
        return { rows: [{ id: '7' }] }
      }
      return { rows: [] }
    })
    await expect(storeExtractedCandidates(database.pool, [candidate])).resolves.toEqual({
      inserted: 1,
      refreshed: 0,
    })
    await expect(storeExtractedCandidates(database.pool, [candidate])).resolves.toEqual({
      inserted: 0,
      refreshed: 0,
    })
    expect(database.query.mock.calls.map((call) => String(call[0])).join('\n'))
      .not.toContain('INSERT INTO agent_knowledge_documents')
  })

  it('refreshes only tenantless quarantined legacy candidates and audits the DLP version', async () => {
    const database = fakePool((sql) => {
      if (sql.startsWith('UPDATE agent_knowledge_candidates candidate')) return { rows: [{ id: '7' }] }
      return { rows: [] }
    })
    await expect(storeExtractedCandidates(database.pool, [candidate])).resolves.toEqual({
      inserted: 0,
      refreshed: 1,
    })
    const refreshSql = String(database.query.mock.calls.find((call) =>
      String(call[0]).startsWith('UPDATE agent_knowledge_candidates candidate'),
    )?.[0])
    expect(refreshSql).toContain('target_tenant IS NULL')
    expect(refreshSql).toContain("status = 'quarantined'")
    expect(refreshSql).toContain('published_document_id IS NULL')
    expect(database.query.mock.calls.some((call) =>
      String(call[0]).includes("'redaction_refreshed'"),
    )).toBe(true)
  })

  it('redacts stale quarantined rows in place without deleting them', async () => {
    const database = fakePool((sql) => {
      if (sql.includes('FROM agent_knowledge_candidates')) {
        return { rows: [{
          id: '8', candidate_key: 'removed', source_namespace: candidate.sourceNamespace,
          target_tenant: null, question_redacted: 'old', answer_redacted: 'old',
          content_hash: 'old', status: 'quarantined', published_document_id: null,
        }] }
      }
      return { rows: [] }
    })
    await expect(
      sanitizeStaleCandidates(
        database.pool,
        'hubspot-conversations-v3',
        [candidate.candidateKey, ...candidate.previousCandidateKeys],
        3,
      ),
    ).resolves.toBe(1)
    const sql = String(database.query.mock.calls.find((call) =>
      String(call[0]).includes('FROM agent_knowledge_candidates'),
    )?.[0])
    expect(sql).toContain('source_namespace = $1')
    expect(sql).toContain('NOT (candidate_key = ANY($3::text[]))')
    expect(sql).not.toContain('DELETE')
  })

  it('retires a published document atomically when a reviewer rejects it', async () => {
    const database = fakePool((sql) => {
      if (sql.includes('FROM agent_knowledge_candidates')) {
        return { rows: [{
          id: '7', candidate_key: candidate.candidateKey, source_namespace: candidate.sourceNamespace,
          target_tenant: 'saas', question_redacted: candidate.questionRedacted,
          answer_redacted: candidate.answerRedacted, content_hash: candidate.contentHash,
          status: 'published', published_document_id: '11',
        }] }
      }
      return { rows: [] }
    })
    await rejectCandidate(database.pool, '7', 'reviewer-1')
    const statements = database.query.mock.calls.map((call) => String(call[0])).join('\n')
    expect(statements).toContain("publication_status = 'retired'")
    expect(statements).toContain('learning_candidate_id = NULL')
    expect(statements).toContain("status = 'rejected'")
  })

  it('retires stale published knowledge and moves its redacted candidate back to review', async () => {
    const database = fakePool((sql) => {
      if (sql.includes('FROM agent_knowledge_candidates')) {
        return { rows: [{
          id: '7', candidate_key: candidate.candidateKey, source_namespace: candidate.sourceNamespace,
          target_tenant: 'saas', question_redacted: 'old', answer_redacted: 'old',
          content_hash: 'old', status: 'published', published_document_id: '11',
        }] }
      }
      return { rows: [] }
    })
    await expect(refreshReviewedCandidates(database.pool, [candidate])).resolves.toBe(1)
    const statements = database.query.mock.calls.map((call) => String(call[0])).join('\n')
    expect(statements).toContain("status = 'pending_review'")
    expect(statements).toContain("publication_status = 'retired'")
    expect(statements).toContain('redaction_refreshed')
  })

  it('rejects approval into a different tenant', async () => {
    const database = fakePool((sql) => {
      if (sql.includes('FROM agent_knowledge_candidates')) {
        return {
          rows: [{
            id: '7', candidate_key: candidate.candidateKey, source_namespace: candidate.sourceNamespace,
            target_tenant: 'saas', question_redacted: candidate.questionRedacted,
            answer_redacted: candidate.answerRedacted, content_hash: candidate.contentHash,
            status: 'pending_review',
          }],
        }
      }
      return { rows: [] }
    })
    await expect(approveCandidate(database.pool, '7', 'new_academy', 'reviewer-1'))
      .rejects.toThrow(/another tenant/)
    expect(database.query).toHaveBeenCalledWith('ROLLBACK')
  })

  it('publishes only an approved tenant-bound candidate', async () => {
    const database = fakePool((sql) => {
      if (sql.includes('FROM agent_knowledge_candidates')) {
        return {
          rows: [{
            id: '7', candidate_key: candidate.candidateKey, source_namespace: candidate.sourceNamespace,
            target_tenant: 'saas', question_redacted: candidate.questionRedacted,
            answer_redacted: candidate.answerRedacted, content_hash: candidate.contentHash,
            status: 'approved',
          }],
        }
      }
      if (sql.includes('INSERT INTO agent_knowledge_documents')) return { rows: [{ id: '11' }] }
      return { rows: [] }
    })
    await publishCandidate(database.pool, '7', 'reviewer-1')
    const calls = database.query.mock.calls
    const publication = calls.find((call) => String(call[0]).includes('INSERT INTO agent_knowledge_documents'))
    expect(publication?.[1]?.[0]).toBe('saas')
    expect(calls.some((call) => String(call[0]).includes("status = 'published'"))).toBe(true)
  })

  it('retires published knowledge immediately on negative feedback and never promotes on helpful feedback', async () => {
    const rows = [{
      id: '7', candidate_key: candidate.candidateKey, source_namespace: candidate.sourceNamespace,
      target_tenant: 'saas', question_redacted: candidate.questionRedacted,
      answer_redacted: candidate.answerRedacted, content_hash: candidate.contentHash,
      status: 'published',
    }]
    const negative = fakePool((sql) => {
      if (sql.includes('FROM agent_knowledge_candidates')) return { rows }
      if (sql.includes('INSERT INTO agent_learning_feedback')) return { rows: [{ id: '9' }] }
      return { rows: [] }
    })
    await recordLearningFeedback(negative.pool, {
      tenantKey: 'saas', conversationId: 1, sourceMessageId: 2, candidateId: '7', rating: 'unhelpful',
    })
    expect(negative.query.mock.calls.some((call) =>
      String(call[0]).includes("publication_status = 'retired'"),
    )).toBe(true)

    const positive = fakePool((sql) => {
      if (sql.includes('FROM agent_knowledge_candidates')) return { rows }
      if (sql.includes('INSERT INTO agent_learning_feedback')) return { rows: [{ id: '10' }] }
      return { rows: [] }
    })
    await recordLearningFeedback(positive.pool, {
      tenantKey: 'saas', conversationId: 1, sourceMessageId: 3, candidateId: '7', rating: 'helpful',
    })
    const statements = positive.query.mock.calls.map((call) => String(call[0])).join('\n')
    expect(statements).not.toContain('INSERT INTO agent_knowledge_documents')
    expect(statements).not.toContain("status = 'approved'")
  })
})
