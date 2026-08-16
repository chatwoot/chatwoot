import { describe, expect, it, vi } from 'vitest'
import { ChatwootApiError, ChatwootClient } from '../src/chatwoot-client.js'
import { tenants } from './fixtures.js'

describe('ChatwootClient', () => {
  it('uses only the tenant AgentBot token and opens a handoff', async () => {
    const request = vi.fn().mockImplementation(() =>
      Promise.resolve(new Response('{"payload":[]}', { status: 200 })),
    )
    const client = new ChatwootClient('https://chat.example.test', request)
    await client.handoff(tenants[1]!, 77)
    expect(request).toHaveBeenCalledOnce()
    expect(request).toHaveBeenCalledWith(
      'https://chat.example.test/api/v1/accounts/202/conversations/77/toggle_status',
      expect.objectContaining({
        body: JSON.stringify({ status: 'open' }),
        headers: expect.objectContaining({
          api_access_token: tenants[1]!.agentBotToken,
          'x-forwarded-proto': 'https',
        }),
      }),
    )
  })

  it('does not leak an upstream response or token in errors', async () => {
    const client = new ChatwootClient('https://chat.example.test', vi.fn().mockResolvedValue(new Response('secret upstream response', { status: 500 })))
    const call = client.sendMessage(tenants[0]!, 77, 'Antwort', 55)
    await expect(call).rejects.toEqual(expect.objectContaining<Partial<ChatwootApiError>>({ status: 500 }))
    await expect(call).rejects.not.toThrow(/secret upstream|saas-agent-bot-token/)
  })
})
