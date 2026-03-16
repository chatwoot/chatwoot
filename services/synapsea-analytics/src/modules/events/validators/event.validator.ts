import { z } from 'zod';

export const analyticsEventSchema = z.object({
  eventType: z.string().min(1),
  source: z.enum(['chatwoot', 'connect', 'ai-service']),
  externalId: z.string().optional(),
  occurredAt: z.string().datetime(),
  payload: z.record(z.unknown()),
});

export type AnalyticsEventPayload = z.infer<typeof analyticsEventSchema>;
