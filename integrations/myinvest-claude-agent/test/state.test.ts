import { describe, expect, it, vi } from 'vitest'
import { PostgresAgentState } from '../src/state.js'

describe('PostgresAgentState', () => {
  it('binds tenant and conversation to persistent handoff checks', async () => {
    const query = vi.fn().mockResolvedValue({ rows: [{ exists: true }] })
    const state = new PostgresAgentState({ query })
    await expect(state.isHandedOff('legacy_academy', 42)).resolves.toBe(true)
    expect(query.mock.calls[0]![0]).toContain('tenant_key = $1')
    expect(query.mock.calls[0]![1]).toEqual(['legacy_academy', 42])
  })

  it('uses a tenant-scoped delivery ledger', async () => {
    const query = vi.fn().mockResolvedValue({ rows: [{ status: 'processing', acquired: true }] })
    const state = new PostgresAgentState({ query })
    await expect(state.beginDelivery('saas', 55, 9, '2026-08-16T18:30:44.414Z')).resolves.toEqual({ status: 'processing', acquired: true })
    expect(query.mock.calls[0]![0]).toContain('ON CONFLICT (tenant_key, message_id) DO UPDATE')
    expect(query.mock.calls[0]![0]).toContain('agent_delivery_ledger.conversation_id < 0')
    expect(query.mock.calls[0]![0]).toContain('$4::timestamptz > agent_delivery_ledger.updated_at')
    expect(query.mock.calls[0]![0]).toContain("status = 'processing'")
    expect(query.mock.calls[0]![1]).toEqual(['saas', 55, 9, '2026-08-16T18:30:44.414Z'])
  })
})
