import { z } from 'zod'

export const tenantKeySchema = z.enum(['saas', 'new_academy', 'legacy_academy'])
export type TenantKey = z.infer<typeof tenantKeySchema>

export const chatwootWebhookSchema = z
  .object({
    event: z.string(),
    id: z.number().int().positive(),
    created_at: z.string().datetime(),
    content: z.string().default(''),
    message_type: z.string(),
    private: z.boolean().optional().default(false),
    account: z.object({ id: z.number().int().positive() }),
    conversation: z.object({ id: z.number().int().positive() }),
  })
  .passthrough()

export type ChatwootWebhookPayload = z.infer<typeof chatwootWebhookSchema>

export interface KnowledgeHit {
  sourceId: string
  title: string
  content: string
  metadata: Record<string, unknown>
  score: number
}
