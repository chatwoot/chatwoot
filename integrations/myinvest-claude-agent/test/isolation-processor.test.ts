import { describe, expect, it, vi } from 'vitest'
import { PostgresKnowledgeRepository } from '../src/knowledge/repository.js'
import { MessageProcessor } from '../src/processor.js'
import { incomingPayload, tenants } from './fixtures.js'

describe('knowledge isolation', () => {
  it('binds tenant_key and never widens an empty result', async () => {
    const query = vi.fn().mockResolvedValue({ rows: [] })
    const repository = new PostgresKnowledgeRepository({ query })
    expect(await repository.search('new_academy', 'Provision', 4)).toEqual([])
    expect(query.mock.calls[0]![0]).toContain('tenant_key = $1')
    expect(query.mock.calls[0]![0]).toContain("publication_status = 'published'")
    expect(query.mock.calls[0]![0]).toContain('active = true')
    expect(query.mock.calls[0]![1]).toEqual(['new_academy', 'Provision', 4])
    // OR-Fallback bei leerem Ergebnis bleibt strikt tenant-gebunden.
    expect(query).toHaveBeenCalledTimes(2)
    expect(query.mock.calls[1]![0]).toContain('tenant_key = $1')
    expect(query.mock.calls[1]![0]).toContain("publication_status = 'published'")
    expect(query.mock.calls[1]![0]).toContain('active = true')
    expect(query.mock.calls[1]![1]).toEqual(['new_academy', 'Provision', 4])
  })
})

function setup(hits: unknown[] = [{ sourceId: 'source-1', title: 'Onboarding', content: 'Kontoeinrichtung', metadata: {}, score: 0.4 }]) {
  const search = vi.fn().mockResolvedValue(hits)
  const answer = vi.fn().mockResolvedValue({
    text: 'Du startest mit der Kontoeinrichtung.',
    sourceIds: ['source-1'],
  })
  const sendMessage = vi.fn().mockResolvedValue(undefined)
  const handoff = vi.fn().mockResolvedValue(undefined)
  const state = {
    isHandedOff: vi.fn().mockResolvedValue(false),
    beginDelivery: vi.fn().mockResolvedValue({ status: 'processing', acquired: true }),
    markSending: vi.fn().mockResolvedValue(undefined),
    completeDelivery: vi.fn().mockResolvedValue(undefined),
    markHandedOff: vi.fn().mockResolvedValue(undefined),
  }
  const processor = new MessageProcessor({
    knowledge: { search },
    claude: { answer },
    chatwoot: { sendMessage, handoff },
    state,
    minRetrievalScore: 0.1,
    maxSources: 4,
  })
  return { processor, search, answer, sendMessage, handoff, state }
}

describe('MessageProcessor', () => {
  it('uses only the configured tenant and hands off unsafe or unsupported questions', async () => {
    const supported = setup()
    await supported.processor.process({ tenant: tenants[1]!, payload: incomingPayload({ account: { id: 202 } }) })
    expect(supported.search).toHaveBeenCalledWith('new_academy', expect.any(String), 4)
    expect(supported.answer).toHaveBeenCalledWith(expect.objectContaining({ tenantKey: 'new_academy' }))
    expect(supported.sendMessage).toHaveBeenCalledOnce()

    for (const content of [
      'Ich möchte mit einem Menschen sprechen.',
      'Ist diese Klausel rechtlich wirksam?',
      'Wie bezahle ich die Rechnung?',
      'Welche Anlage bringt die beste Rendite und wie versteuere ich sie?',
    ]) {
      const unsafe = setup()
      await unsafe.processor.process({ tenant: tenants[0]!, payload: incomingPayload({ content }) })
      expect(unsafe.answer).not.toHaveBeenCalled()
      expect(unsafe.handoff).toHaveBeenCalledOnce()
    }

    const unsupported = setup([])
    await unsupported.processor.process({ tenant: tenants[0]!, payload: incomingPayload() })
    expect(unsupported.answer).not.toHaveBeenCalled()
    expect(unsupported.handoff).toHaveBeenCalledOnce()
  })

  it('persists handoff and safely suppresses duplicate or ambiguous deliveries', async () => {
    const handedOff = setup()
    handedOff.state.isHandedOff.mockResolvedValueOnce(true)
    await handedOff.processor.process({ tenant: tenants[0]!, payload: incomingPayload() })
    expect(handedOff.answer).not.toHaveBeenCalled()
    expect(handedOff.sendMessage).not.toHaveBeenCalled()

    const completed = setup()
    completed.state.beginDelivery.mockResolvedValueOnce({ status: 'replied', acquired: false })
    await completed.processor.process({ tenant: tenants[0]!, payload: incomingPayload() })
    expect(completed.sendMessage).not.toHaveBeenCalled()
    expect(completed.handoff).not.toHaveBeenCalled()

    for (const status of ['processing', 'sending'] as const) {
      const ambiguous = setup()
      ambiguous.state.beginDelivery.mockResolvedValueOnce({ status, acquired: false })
      await ambiguous.processor.process({ tenant: tenants[0]!, payload: incomingPayload() })
      expect(ambiguous.sendMessage).not.toHaveBeenCalled()
      expect(ambiguous.handoff).toHaveBeenCalledOnce()
      expect(ambiguous.state.completeDelivery).toHaveBeenCalledWith('saas', 55, 'handed_off')
    }
  })

  it('cites only sources selected by the model', async () => {
    const selected = setup([
      { sourceId: 'source-1', title: 'Quelle Eins', content: 'A', metadata: {}, score: 0.4 },
      { sourceId: 'source-2', title: 'Quelle Zwei', content: 'B', metadata: {}, score: 0.3 },
    ])
    selected.answer.mockResolvedValueOnce({ text: 'Antwort', sourceIds: ['source-2'] })
    await selected.processor.process({ tenant: tenants[0]!, payload: incomingPayload() })
    expect(selected.sendMessage).toHaveBeenCalledWith(
      tenants[0],
      77,
      expect.stringContaining('Quelle Zwei [source-2]'),
      55,
    )
    expect(selected.sendMessage.mock.calls[0]![2]).not.toContain('Quelle Eins')
  })
})
