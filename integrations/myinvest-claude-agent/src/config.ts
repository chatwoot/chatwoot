import { z } from 'zod'
import { tenantKeySchema, type TenantKey } from './domain.js'

const tenantSchema = z.object({
  key: tenantKeySchema,
  accountId: z.number().int().positive(),
  webhookSecret: z.string().min(24),
  agentBotToken: z.string().min(24),
})

export type TenantConfig = z.infer<typeof tenantSchema>

export interface TenantRegistry {
  readonly all: readonly TenantConfig[]
  requireByAccountId(accountId: number): TenantConfig
  requireByKey(key: TenantKey): TenantConfig
}

export function buildTenantRegistry(values: readonly TenantConfig[]): TenantRegistry {
  const tenants = values.map((value) => tenantSchema.parse(value))
  if (tenants.length !== 3 || new Set(tenants.map(({ key }) => key)).size !== 3) {
    throw new Error('Exactly one configuration for each of the three tenants is required')
  }
  const accountIds = tenants.map(({ accountId }) => accountId)
  if (new Set(accountIds).size !== accountIds.length) {
    throw new Error('Each tenant must use a unique Chatwoot account ID')
  }
  const credentials = tenants.flatMap(({ webhookSecret, agentBotToken }) => [
    webhookSecret,
    agentBotToken,
  ])
  if (new Set(credentials).size !== credentials.length) {
    throw new Error('Tenant credentials must never be shared')
  }

  const byAccountId = new Map(tenants.map((tenant) => [tenant.accountId, tenant]))
  const byKey = new Map(tenants.map((tenant) => [tenant.key, tenant]))
  return {
    all: tenants,
    requireByAccountId(accountId) {
      const tenant = byAccountId.get(accountId)
      if (!tenant) throw new Error(`Unknown Chatwoot account ID: ${accountId}`)
      return tenant
    },
    requireByKey(key) {
      const tenant = byKey.get(key)
      if (!tenant) throw new Error(`Unknown tenant key: ${key}`)
      return tenant
    },
  }
}

export function parseTenantConfig(value: string): TenantConfig[] {
  let input: unknown
  try {
    input = JSON.parse(value)
  } catch {
    throw new Error('TENANTS_JSON must be valid JSON')
  }
  return [...buildTenantRegistry(z.array(tenantSchema).parse(input)).all]
}

const envSchema = z.object({
  LOCAL_SMOKE: z.enum(['true', 'false']).default('false').transform((value) => value === 'true'),
  LOCAL_FAKE_CLAUDE_ANSWER: z.string().max(8_000).optional(),
  PORT: z.coerce.number().int().min(1).max(65_535).default(8080),
  RUN_MODE: z.enum(['all', 'web', 'worker']).default('all'),
  DATABASE_URL: z.string().min(1),
  REDIS_URL: z.string().min(1),
  CHATWOOT_BASE_URL: z.string().url(),
  TENANTS_JSON: z.string().min(1),
  WEBHOOK_REPLAY_WINDOW_SECONDS: z.coerce.number().int().min(30).max(3600).default(300),
  DELIVERY_RETENTION_SECONDS: z.coerce.number().int().min(3600).default(86400),
  MAX_BODY_BYTES: z.coerce.number().int().min(1024).max(1048576).default(262144),
  KNOWLEDGE_MIN_SCORE: z.coerce.number().min(0).max(1).default(0.05),
  KNOWLEDGE_MAX_SOURCES: z.coerce.number().int().min(1).max(10).default(4),
  ANTHROPIC_PROVIDER: z.enum(['direct', 'bedrock']).default('direct'),
  ANTHROPIC_API_KEY: z.string().optional(),
  ANTHROPIC_MODEL: z.string().default('claude-sonnet-4-5'),
  AWS_REGION: z.string().default('eu-central-1'),
  BEDROCK_MODEL: z.string().default('eu.anthropic.claude-sonnet-4-5-20250929-v1:0'),
})

export type AppConfig = ReturnType<typeof loadConfig>

export function loadConfig(environment: NodeJS.ProcessEnv = process.env) {
  const env = envSchema.parse(environment)
  if (env.LOCAL_FAKE_CLAUDE_ANSWER && !env.LOCAL_SMOKE) {
    throw new Error('LOCAL_FAKE_CLAUDE_ANSWER is restricted to LOCAL_SMOKE=true')
  }
  if (
    !env.LOCAL_FAKE_CLAUDE_ANSWER &&
    env.ANTHROPIC_PROVIDER === 'direct' &&
    !env.ANTHROPIC_API_KEY
  ) {
    throw new Error('ANTHROPIC_API_KEY is required for ANTHROPIC_PROVIDER=direct')
  }
  return { ...env, tenants: buildTenantRegistry(parseTenantConfig(env.TENANTS_JSON)) }
}
