import { describe, expect, it, vi } from 'vitest'
import { PostgresKnowledgeRepository } from '../src/knowledge/repository.js'

function row(title: string, score: number) {
  return { source_id: title, title, content: `Inhalt ${title}`, metadata: {}, score }
}

describe('knowledge search', () => {
  it('returns strict AND matches without touching the relaxed fallback', async () => {
    const query = vi.fn().mockResolvedValue({ rows: [row('Was-kostet-MyInvest-Pro', 0.3)] })
    const repository = new PostgresKnowledgeRepository({ query })

    const hits = await repository.search('saas', 'Was kostet MyInvest Pro?', 4)

    expect(hits.map((hit) => hit.title)).toEqual(['Was-kostet-MyInvest-Pro'])
    expect(query).toHaveBeenCalledTimes(1)
    expect(query.mock.calls[0]?.[0]).toContain('websearch_to_tsquery')
  })

  it('falls back to OR matching when the strict query finds nothing', async () => {
    const query = vi
      .fn()
      .mockResolvedValueOnce({ rows: [] })
      .mockResolvedValueOnce({ rows: [row('KfW-Foerderung', 0.6)] })
    const repository = new PostgresKnowledgeRepository({ query })

    const hits = await repository.search('saas', 'Welche KfW-Förderung gibt es?', 4)

    expect(hits.map((hit) => hit.title)).toEqual(['KfW-Foerderung'])
    expect(query).toHaveBeenCalledTimes(2)
    expect(query.mock.calls[1]?.[0]).toContain('plainto_tsquery')
  })

  it('returns empty when both queries find nothing', async () => {
    const query = vi.fn().mockResolvedValue({ rows: [] })
    const repository = new PostgresKnowledgeRepository({ query })

    const hits = await repository.search('saas', 'Duesenjet mieten', 4)

    expect(hits).toEqual([])
    expect(query).toHaveBeenCalledTimes(2)
  })
})
