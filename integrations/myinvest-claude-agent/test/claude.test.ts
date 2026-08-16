import { describe, expect, it, vi } from 'vitest'
import { ClaudeClient } from '../src/claude.js'

const source = {
  sourceId: 'approved-1',
  title: 'Freigegeben',
  content: 'Die Einrichtung erfolgt im Bereich Einstellungen.',
  metadata: {},
  score: 1,
}

function client(decision: unknown) {
  const create = vi.fn().mockResolvedValue({
    content: [{ type: 'text', text: JSON.stringify(decision) }],
  })
  return { client: new ClaudeClient({ messages: { create } }, 'test-model'), create }
}

describe('ClaudeClient', () => {
  it('accepts only a confident answer tied to an allowed source', async () => {
    const valid = client({
      action: 'answer',
      answer: 'Unter Einstellungen.',
      confidence: 0.9,
      source_ids: ['approved-1'],
    })
    await expect(
      valid.client.answer({ tenantKey: 'saas', question: 'Wo?', sources: [source] }),
    ).resolves.toBe('Unter Einstellungen.')
    expect(valid.create).toHaveBeenCalledWith(
      expect.objectContaining({ model: 'test-model', temperature: 0 }),
    )
  })

  it.each([
    { action: 'handoff', answer: '', confidence: 1, source_ids: ['approved-1'] },
    { action: 'answer', answer: 'Unsicher', confidence: 0.64, source_ids: ['approved-1'] },
    { action: 'answer', answer: 'Erfunden', confidence: 1, source_ids: ['foreign'] },
  ])('rejects unsafe structured decisions', async (decision) => {
    const unsafe = client(decision)
    await expect(
      unsafe.client.answer({ tenantKey: 'saas', question: 'Wo?', sources: [source] }),
    ).rejects.toThrow()
  })
})
