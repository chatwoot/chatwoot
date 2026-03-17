import { z } from 'zod';

export const askAiSchema = z.object({
  question: z.string().min(5),
  filters: z
    .object({
      dateFrom: z.string().datetime().optional(),
      dateTo: z.string().datetime().optional(),
      inboxIds: z.array(z.string()).optional(),
    })
    .optional(),
});
