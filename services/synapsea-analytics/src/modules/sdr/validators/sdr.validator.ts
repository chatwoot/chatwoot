import { z } from 'zod';

export const leadImportSchema = z.object({
  leads: z
    .array(
      z.object({
        name: z.string().min(2),
        phone: z.string().optional(),
        email: z.string().email().optional(),
        company: z.string().optional(),
        segment: z.string().optional(),
        city: z.string().optional(),
        role: z.string().optional(),
      })
    )
    .min(1),
});

export const sdrStartSchema = z.object({
  leadId: z.string().optional(),
  channel: z
    .enum(['whatsapp', 'instagram', 'webchat', 'email', 'sms'])
    .default('whatsapp'),
});
