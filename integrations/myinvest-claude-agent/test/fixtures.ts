import { createHmac } from 'node:crypto'
import type { TenantConfig } from '../src/config.js'
import type { ChatwootWebhookPayload } from '../src/domain.js'

export const tenants: TenantConfig[] = [
  { key: 'saas', accountId: 101, webhookSecret: 'saas-webhook-secret-with-32-bytes', agentBotToken: 'saas-agent-bot-token-with-32-bytes' },
  { key: 'new_academy', accountId: 202, webhookSecret: 'new-academy-secret-with-32-bytes', agentBotToken: 'new-academy-token-with-32-bytes' },
  { key: 'legacy_academy', accountId: 303, webhookSecret: 'legacy-academy-secret-with-32-bytes', agentBotToken: 'legacy-academy-token-with-32-bytes' },
]

export function incomingPayload(overrides: Partial<ChatwootWebhookPayload> = {}): ChatwootWebhookPayload {
  return {
    event: 'message_created', id: 55, created_at: '2026-08-16T18:30:44.414Z', content: 'Wie funktioniert das Onboarding?',
    message_type: 'incoming', private: false, account: { id: 101 }, conversation: { id: 77 },
    ...overrides,
  }
}

export function signedHeaders(rawBody: string, secret: string, nowMs: number) {
  const timestamp = Math.floor(nowMs / 1000).toString()
  return {
    'x-chatwoot-delivery': 'delivery-123',
    'x-chatwoot-timestamp': timestamp,
    'x-chatwoot-signature': `sha256=${createHmac('sha256', secret).update(`${timestamp}.${rawBody}`).digest('hex')}`,
  }
}
