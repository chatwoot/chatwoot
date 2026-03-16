import { z } from 'zod';

export const redistributeSchema = z.object({
  fromQueue: z.string().min(1),
  toQueue: z.string().min(1),
  limit: z.number().int().positive().max(200),
});
