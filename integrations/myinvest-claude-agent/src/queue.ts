import { createHash } from 'node:crypto'
import type { JobsOptions, Queue } from 'bullmq'
import type { TenantConfig } from './config.js'
import type { ChatwootWebhookPayload, TenantKey } from './domain.js'

export const QUEUE_NAME = 'myinvest-chatwoot-agent'

export interface DeliveryJob {
  tenantKey: TenantKey
  payload: ChatwootWebhookPayload
}

interface QueueLike {
  add(name: string, data: DeliveryJob, options: JobsOptions): Promise<unknown>
}

export function jobIdForDelivery(tenantKey: TenantKey, deliveryId: string): string {
  return createHash('sha256').update(`${tenantKey}\0${deliveryId}`).digest('hex')
}

export class DeliveryQueue {
  constructor(
    private readonly queue: QueueLike | Queue<DeliveryJob>,
    private readonly options: { retentionSeconds: number },
  ) {}

  async enqueue(
    tenant: TenantConfig,
    deliveryId: string,
    payload: ChatwootWebhookPayload,
  ): Promise<void> {
    await this.queue.add(
      'process-incoming-message',
      { tenantKey: tenant.key, payload },
      {
        jobId: jobIdForDelivery(tenant.key, deliveryId),
        attempts: 3,
        backoff: { type: 'exponential', delay: 2_000 },
        removeOnComplete: { age: this.options.retentionSeconds },
        removeOnFail: { age: this.options.retentionSeconds },
      },
    )
  }
}
