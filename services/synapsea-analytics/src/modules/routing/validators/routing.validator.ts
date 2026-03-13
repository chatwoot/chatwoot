import { z } from 'zod';

export const createTicketSchema = z.object({
  subject: z.string().min(3),
  message: z.string().min(5),
});

export const transferTicketSchema = z.object({
  toAgentId: z.string().optional(),
  toQueueId: z.string().optional(),
  reason: z.string().min(5),
  summary: z.string().optional(),
  nextStep: z.string().optional(),
});

export const assignTicketSchema = z.object({
  assigneeId: z.string().min(1),
});

export const enqueueTicketSchema = z.object({
  queueId: z.string().min(1),
});

export const escalateTicketSchema = z.object({
  reason: z.string().min(5),
});
