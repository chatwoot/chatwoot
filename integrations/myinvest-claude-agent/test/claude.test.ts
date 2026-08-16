import { describe, expect, it, vi } from 'vitest'
import { ClaudeClient, OpenAICompatibleLocalClient } from '../src/claude.js'

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
    ).resolves.toEqual({ text: 'Unter Einstellungen.', sourceIds: ['approved-1'] })
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

describe('OpenAICompatibleLocalClient', () => {
  it('uses the internal JSON endpoint without auth and validates selected sources', async () => {
    const fetchImplementation = vi.fn().mockResolvedValue(
      new Response(JSON.stringify({
        choices: [{ message: { content: JSON.stringify({
          action: 'answer', answer: 'Unter Einstellungen.', confidence: 0.9,
          source_ids: ['approved-1'],
        }) } }],
      }), { status: 200 }),
    )
    const local = new OpenAICompatibleLocalClient(
      'http://local-llm:8000/v1',
      'local-model',
      5_000,
      undefined,
      fetchImplementation,
    )
    await expect(local.answer({ tenantKey: 'saas', question: 'Wo?', sources: [source] }))
      .resolves.toEqual({ text: 'Unter Einstellungen.', sourceIds: ['approved-1'] })
    const [url, request] = fetchImplementation.mock.calls[0]!
    expect(url).toBe('http://local-llm:8000/v1/chat/completions')
    expect(request.redirect).toBe('error')
    expect(request.headers).not.toHaveProperty('authorization')
    expect(JSON.parse(request.body)).toMatchObject({
      model: 'local-model',
      stream: false,
      think: false,
      temperature: 0,
      response_format: { type: 'json_object' },
    })
  })

  it('fails closed on HTTP errors and foreign source IDs', async () => {
    const failed = new OpenAICompatibleLocalClient(
      'http://local-llm:8000/v1', 'local-model', 5_000, undefined,
      vi.fn().mockResolvedValue(new Response('', { status: 503 })),
    )
    await expect(failed.answer({ tenantKey: 'saas', question: 'Wo?', sources: [source] }))
      .rejects.toThrow(/status 503/)

    const foreign = new OpenAICompatibleLocalClient(
      'http://local-llm:8000/v1', 'local-model', 5_000, undefined,
      vi.fn().mockResolvedValue(new Response(JSON.stringify({
        choices: [{ message: { content: JSON.stringify({
          action: 'answer', answer: 'Erfunden', confidence: 1, source_ids: ['foreign'],
        }) } }],
      }), { status: 200 })),
    )
    await expect(foreign.answer({ tenantKey: 'saas', question: 'Wo?', sources: [source] }))
      .rejects.toThrow(/handoff/)
  })

  it('bounds response parsing and aborts stalled requests', async () => {
    for (const body of ['not-json', 'x'.repeat(1_000_001)]) {
      const local = new OpenAICompatibleLocalClient(
        'http://local-llm:8000/v1', 'local-model', 5_000, undefined,
        vi.fn().mockResolvedValue(new Response(body, { status: 200 })),
      )
      await expect(local.answer({ tenantKey: 'saas', question: 'Wo?', sources: [source] }))
        .rejects.toThrow()
    }

    const stalledFetch = vi.fn((_url: string | URL | Request, request?: RequestInit) =>
      new Promise<Response>((_resolve, reject) => {
        request?.signal?.addEventListener('abort', () => reject(request.signal?.reason), { once: true })
      }),
    ) as unknown as typeof fetch
    const stalled = new OpenAICompatibleLocalClient(
      'http://local-llm:8000/v1', 'local-model', 10, undefined, stalledFetch,
    )
    await expect(stalled.answer({ tenantKey: 'saas', question: 'Wo?', sources: [source] }))
      .rejects.toThrow()
  })
})
