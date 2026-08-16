import type { TenantRegistry } from '../config.js'
import { chatwootWebhookSchema, type ChatwootWebhookPayload } from '../domain.js'
import { verifyChatwootSignature } from './signature.js'

export type WebhookHeaders = Record<string, string | string[] | undefined>

interface QueuePort {
  enqueue(
    tenant: ReturnType<TenantRegistry['requireByAccountId']>,
    deliveryId: string,
    payload: ChatwootWebhookPayload,
  ): Promise<void>
}

export class QueueUnavailableError extends Error {
  constructor() {
    super('Agent queue is unavailable')
    this.name = 'QueueUnavailableError'
  }
}

export class WebhookController {
  constructor(
    private readonly dependencies: {
      tenants: TenantRegistry
      queue: QueuePort
      replayWindowSeconds: number
      now?: () => number
    },
  ) {}

  async handle(rawBody: string, headers: WebhookHeaders) {
    const parsedUnknown: unknown = JSON.parse(rawBody)
    const accountShape = chatwootWebhookSchema.pick({ account: true }).parse(parsedUnknown)
    const tenant = this.dependencies.tenants.requireByAccountId(accountShape.account.id)
    const timestamp = requiredHeader(headers, 'x-chatwoot-timestamp')
    const signature = requiredHeader(headers, 'x-chatwoot-signature')
    const deliveryId = requiredHeader(headers, 'x-chatwoot-delivery')
    if (!/^[A-Za-z0-9._-]{8,200}$/.test(deliveryId)) {
      throw new Error('Invalid Chatwoot delivery ID')
    }
    verifyChatwootSignature({
      rawBody,
      secret: tenant.webhookSecret,
      timestamp,
      signature,
      nowMs: this.dependencies.now?.() ?? Date.now(),
      replayWindowSeconds: this.dependencies.replayWindowSeconds,
    })
    const payload = chatwootWebhookSchema.parse(parsedUnknown)
    if (
      payload.event !== 'message_created' ||
      payload.message_type !== 'incoming' ||
      payload.private
    ) {
      return { status: 200, body: { accepted: false } } as const
    }
    try {
      await this.dependencies.queue.enqueue(tenant, deliveryId, payload)
    } catch {
      throw new QueueUnavailableError()
    }
    return { status: 202, body: { accepted: true } } as const
  }
}

function requiredHeader(headers: WebhookHeaders, name: string): string {
  const value = headers[name]
  if (typeof value !== 'string' || value.length === 0) {
    throw new Error(`Missing required header: ${name}`)
  }
  return value
}
