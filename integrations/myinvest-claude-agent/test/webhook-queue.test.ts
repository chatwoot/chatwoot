import { describe, expect, it, vi } from 'vitest'
import { buildTenantRegistry } from '../src/config.js'
import { DeliveryQueue, jobIdForDelivery } from '../src/queue.js'
import { QueueUnavailableError, WebhookController } from '../src/webhook/controller.js'
import { incomingPayload, signedHeaders, tenants } from './fixtures.js'

describe('WebhookController', () => {
  const nowMs = 1_800_000_000_000
  it('queues only signed incoming message_created events', async () => {
    const enqueue = vi.fn().mockResolvedValue(undefined)
    const controller = new WebhookController({ tenants: buildTenantRegistry(tenants), queue: { enqueue }, replayWindowSeconds: 300, now: () => nowMs })
    const payload = incomingPayload()
    const raw = JSON.stringify(payload)
    expect(await controller.handle(raw, signedHeaders(raw, tenants[0]!.webhookSecret, nowMs))).toEqual({ status: 202, body: { accepted: true } })
    expect(enqueue).toHaveBeenCalledWith(tenants[0], 'delivery-123', payload)
    for (const ignored of [incomingPayload({ event: 'message_updated' }), incomingPayload({ message_type: 'outgoing' }), incomingPayload({ private: true })]) {
      const ignoredRaw = JSON.stringify(ignored)
      expect((await controller.handle(ignoredRaw, signedHeaders(ignoredRaw, tenants[0]!.webhookSecret, nowMs))).status).toBe(200)
    }
  })

  it('turns queue failures into a retryable infrastructure error', async () => {
    const controller = new WebhookController({
      tenants: buildTenantRegistry(tenants),
      queue: { enqueue: vi.fn().mockRejectedValue(new Error('redis down')) },
      replayWindowSeconds: 300,
      now: () => nowMs,
    })
    const raw = JSON.stringify(incomingPayload())
    await expect(
      controller.handle(raw, signedHeaders(raw, tenants[0]!.webhookSecret, nowMs)),
    ).rejects.toBeInstanceOf(QueueUnavailableError)
  })
})

describe('DeliveryQueue', () => {
  it('deduplicates by stable tenant-scoped delivery ID', async () => {
    const add = vi.fn().mockResolvedValue({ id: 'job' })
    const queue = new DeliveryQueue({ add }, { retentionSeconds: 86_400 })
    await queue.enqueue(tenants[0]!, 'same-delivery', incomingPayload())
    expect(add.mock.calls[0]![2].jobId).toBe(jobIdForDelivery('saas', 'same-delivery'))
    expect(jobIdForDelivery('saas', 'same-delivery')).not.toBe(jobIdForDelivery('new_academy', 'same-delivery'))
  })
})
