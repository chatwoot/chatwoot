import { mkdtemp, mkdir, symlink, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { describe, expect, it, vi } from 'vitest'
import { ingestApprovedDirectory, splitKnowledge } from '../src/knowledge/ingest.js'

function pool() {
  const query = vi.fn().mockResolvedValue({ rows: [] })
  return { pool: { connect: vi.fn().mockResolvedValue({ query, release: vi.fn() }) }, query }
}

describe('approved knowledge ingestion', () => {
  it('replaces only one source namespace atomically and is deterministic', async () => {
    const root = await mkdtemp(join(tmpdir(), 'approved-knowledge-'))
    await writeFile(join(root, 'faq.md'), 'Freigegebene Antwort für das Onboarding.', 'utf8')
    const database = pool()
    const first = await ingestApprovedDirectory(database.pool, 'saas', 'saas-help', root)
    const second = await ingestApprovedDirectory(database.pool, 'saas', 'saas-help', root)

    expect(first.batchId).toBe(second.batchId)
    const statements = database.query.mock.calls.map((call) => String(call[0])).join('\n')
    expect(statements).not.toContain('DELETE FROM agent_knowledge_documents')
    expect(statements).toContain('WHERE tenant_key = $1 AND source_namespace = $2')
    expect(statements).toContain("publication_status = 'published'")
  })

  it('rejects raw history bundles and hidden or symlinked content', async () => {
    const raw = await mkdtemp(join(tmpdir(), 'raw-knowledge-'))
    await writeFile(join(raw, 'manifest.json'), JSON.stringify({ knowledge_import: false }), 'utf8')
    await writeFile(join(raw, 'contacts.ndjson'), '{"email":"customer@example.org"}\n', 'utf8')
    await expect(ingestApprovedDirectory(pool().pool, 'saas', 'raw', raw)).rejects.toThrow(
      /History\/export bundles/,
    )

    const hidden = await mkdtemp(join(tmpdir(), 'hidden-knowledge-'))
    await writeFile(join(hidden, '.private.txt'), 'private', 'utf8')
    await expect(ingestApprovedDirectory(pool().pool, 'saas', 'hidden', hidden)).rejects.toThrow(
      /Hidden files/,
    )

    const linked = await mkdtemp(join(tmpdir(), 'linked-knowledge-'))
    const outside = await mkdtemp(join(tmpdir(), 'outside-knowledge-'))
    await writeFile(join(outside, 'customer.txt'), 'customer secret', 'utf8')
    await symlink(join(outside, 'customer.txt'), join(linked, 'customer.txt'))
    await expect(ingestApprovedDirectory(pool().pool, 'saas', 'linked', linked)).rejects.toThrow(
      /Symbolic links/,
    )
  })

  it('hard-splits oversized paragraphs', () => {
    const chunks = splitKnowledge('x'.repeat(7_501), 3_500)
    expect(chunks.map((chunk) => chunk.length)).toEqual([3_500, 3_500, 501])
  })
})
