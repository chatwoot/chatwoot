import { z } from 'zod';

const conditionSchema = z.object({
  field: z.string().min(1),
  operator: z.enum([
    'equals',
    'not_equals',
    'contains',
    'not_contains',
    'greater_than',
    'less_than',
  ]),
  value: z.union([z.string(), z.number(), z.boolean()]),
  logicalGroup: z.enum(['and', 'or']).default('and'),
});

const actionSchema = z.object({
  type: z.enum([
    'add_tag',
    'remove_tag',
    'transfer_to_queue',
    'assign_agent',
    'send_message',
    'create_internal_note',
    'escalate_ticket',
  ]),
  params: z.record(z.union([z.string(), z.number(), z.boolean()])),
  actionOrder: z.number().int().positive(),
});

export const automationPayloadSchema = z.object({
  name: z.string().min(2),
  description: z.string().optional(),
  triggerType: z.enum([
    'message.received',
    'conversation.created',
    'conversation.sla_risk',
    'ai.fallback_detected',
  ]),
  priority: z.number().int().min(1).max(999).default(100),
  stopOnMatch: z.boolean().default(false),
  cooldownSeconds: z.number().int().min(0).max(86400).default(0),
  conditions: z.array(conditionSchema).default([]),
  actions: z.array(actionSchema).min(1),
});

export const executeAutomationSchema = z.object({
  event: z.object({
    type: z.enum([
      'message.received',
      'conversation.created',
      'conversation.sla_risk',
      'ai.fallback_detected',
    ]),
    ticketId: z.string().optional(),
    context: z.record(z.unknown()).default({}),
  }),
});

export const toggleAutomationSchema = z.object({
  isActive: z.boolean(),
});
