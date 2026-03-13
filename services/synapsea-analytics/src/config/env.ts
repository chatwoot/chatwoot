import { z } from 'zod';

const envSchema = z.object({
 codex/transform-chatwoot-into-synapsea-connect-nhivec
  NODE_ENV: z
    .enum(['development', 'test', 'production'])
    .default('development'),
  PORT: z.coerce.number().default(4010),
  // Optional in scaffold mode; required when repositories are connected to Supabase.
  SUPABASE_URL: z.string().url().optional(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1).optional(),

  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().default(4010),
  SUPABASE_URL: z.string().url(),
  SUPABASE_SERVICE_ROLE_KEY: z.string().min(1),
 develop
});

export const env = envSchema.parse(process.env);
