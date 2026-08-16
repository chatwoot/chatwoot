import type { TenantKey } from './domain.js'

export type DeliveryStatus = 'processing' | 'sending' | 'replied' | 'handed_off'
export interface DeliveryClaim {
  status: DeliveryStatus
  acquired: boolean
}

interface QueryResult<Row> {
  rows: Row[]
}

interface Queryable {
  query<Row extends Record<string, unknown>>(
    text: string,
    values?: readonly unknown[],
  ): Promise<QueryResult<Row>>
}

export interface AgentState {
  isHandedOff(tenantKey: TenantKey, conversationId: number): Promise<boolean>
  beginDelivery(
    tenantKey: TenantKey,
    messageId: number,
    conversationId: number,
    eventCreatedAt: string,
  ): Promise<DeliveryClaim>
  markSending(tenantKey: TenantKey, messageId: number): Promise<void>
  completeDelivery(
    tenantKey: TenantKey,
    messageId: number,
    status: Extract<DeliveryStatus, 'replied' | 'handed_off'>,
  ): Promise<void>
  markHandedOff(tenantKey: TenantKey, conversationId: number): Promise<void>
}

export class PostgresAgentState implements AgentState {
  constructor(private readonly database: Queryable) {}

  async isHandedOff(tenantKey: TenantKey, conversationId: number): Promise<boolean> {
    const result = await this.database.query<{ exists: boolean }>(
      `SELECT EXISTS(
         SELECT 1 FROM agent_conversation_states
          WHERE tenant_key = $1 AND conversation_id = $2 AND status = 'handed_off'
       ) AS exists`,
      [tenantKey, conversationId],
    )
    return result.rows[0]?.exists === true
  }

  async beginDelivery(
    tenantKey: TenantKey,
    messageId: number,
    conversationId: number,
    eventCreatedAt: string,
  ): Promise<DeliveryClaim> {
    const result = await this.database.query<{ status: DeliveryStatus; acquired: boolean }>(
      `WITH claimed AS (
         INSERT INTO agent_delivery_ledger (tenant_key, message_id, conversation_id, status)
         VALUES ($1, $2, $3, 'processing')
         ON CONFLICT (tenant_key, message_id) DO UPDATE
           SET conversation_id = EXCLUDED.conversation_id,
               status = 'processing',
               updated_at = now()
         WHERE agent_delivery_ledger.conversation_id < 0
           AND $4::timestamptz > agent_delivery_ledger.updated_at
         RETURNING status, true AS acquired
       )
       SELECT status, acquired FROM claimed
       UNION ALL
       SELECT status, false AS acquired
         FROM agent_delivery_ledger
        WHERE tenant_key = $1 AND message_id = $2
       LIMIT 1`,
      [tenantKey, messageId, conversationId, eventCreatedAt],
    )
    const claim = result.rows[0]
    if (!claim) throw new Error('Delivery ledger did not return a claim')
    return claim
  }

  async markSending(tenantKey: TenantKey, messageId: number): Promise<void> {
    await this.database.query(
      `UPDATE agent_delivery_ledger
          SET status = 'sending', updated_at = now()
        WHERE tenant_key = $1 AND message_id = $2 AND status = 'processing'`,
      [tenantKey, messageId],
    )
  }

  async completeDelivery(
    tenantKey: TenantKey,
    messageId: number,
    status: Extract<DeliveryStatus, 'replied' | 'handed_off'>,
  ): Promise<void> {
    await this.database.query(
      `UPDATE agent_delivery_ledger
          SET status = $3, updated_at = now()
        WHERE tenant_key = $1 AND message_id = $2`,
      [tenantKey, messageId, status],
    )
  }

  async markHandedOff(tenantKey: TenantKey, conversationId: number): Promise<void> {
    await this.database.query(
      `INSERT INTO agent_conversation_states (tenant_key, conversation_id, status)
       VALUES ($1, $2, 'handed_off')
       ON CONFLICT (tenant_key, conversation_id) DO UPDATE
         SET status = 'handed_off', updated_at = now()`,
      [tenantKey, conversationId],
    )
  }
}
