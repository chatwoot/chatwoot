import { z } from 'zod';

const optionalString = z.preprocess(
  value => (value === '' ? undefined : value),
  z.string().optional()
);

const schema = z.object({
  HOST: z.string().default('0.0.0.0'),
  PORT: z.coerce.number().int().positive().default(3400),
  LOG_LEVEL: z.string().default('info'),
  CHATWOOT_PUBLIC_URL: z.string().url().default('http://localhost:3300'),
  CHATWOOT_WEBSITE_TOKEN: optionalString,
  CHATWOOT_WEBHOOK_SECRET: optionalString,
  DEMO_CUSTOMER_IDENTIFIER: z.string().default('demo-customer-001'),
  DEMO_CUSTOMER_NAME: z.string().default('AgentBot Demo Customer'),
  DEMO_CUSTOMER_EMAIL: z.string().email().default('agentbot-demo@example.test'),
  DEMO_CUSTOMER_PHONE: z.string().default('+821012345678')
});

export type AppConfig = z.infer<typeof schema>;

export const loadConfig = (environment: NodeJS.ProcessEnv = process.env): AppConfig =>
  schema.parse(environment);
