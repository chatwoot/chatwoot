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

function emptyStringAsUndefined<T extends z.ZodType>(schema: T) {
  return z.preprocess((value) => value === '' ? undefined : value, schema.optional())
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
  ANTHROPIC_PROVIDER: z.enum(['direct', 'bedrock', 'local']).default('direct'),
  ANTHROPIC_API_KEY: z.string().optional(),
  ANTHROPIC_MODEL: z.string().default('claude-sonnet-4-5'),
  AWS_REGION: z.string().default('eu-central-1'),
  BEDROCK_MODEL: z.string().default('eu.anthropic.claude-sonnet-4-5-20250929-v1:0'),
  LOCAL_LLM_BASE_URL: emptyStringAsUndefined(z.string().url().max(2_048)),
  LOCAL_LLM_MODEL: emptyStringAsUndefined(z.string().min(1).max(255)),
  LOCAL_LLM_ALLOWED_HOSTS: emptyStringAsUndefined(z.string().min(1).max(2_048)),
  LOCAL_LLM_API_KEY: emptyStringAsUndefined(z.string().min(8)),
  LOCAL_LLM_TIMEOUT_MS: z.coerce.number().int().min(1_000).max(120_000).default(30_000),
})

export type AppConfig = ReturnType<typeof loadConfig>

function normalizedHost(value: string): string {
  return value.toLowerCase().replace(/^\[|\]$/g, '').replace(/\.$/, '')
}

function isPrivateIpv4(host: string): boolean {
  const parts = host.split('.').map(Number)
  if (parts.length !== 4 || parts.some((part) => !Number.isInteger(part) || part < 0 || part > 255)) {
    return false
  }
  return (
    parts[0] === 10 ||
    parts[0] === 127 ||
    (parts[0] === 172 && parts[1]! >= 16 && parts[1]! <= 31) ||
    (parts[0] === 192 && parts[1] === 168)
  )
}

function isInternalLlmHost(host: string): boolean {
  if (['169.254.169.254', 'metadata.google.internal', 'metadata.azure.internal'].includes(host)) {
    return false
  }
  if (isPrivateIpv4(host) || host === '::1' || /^(?:fc|fd)[0-9a-f:]+$/i.test(host)) return true
  return /^[a-z][a-z0-9-]{0,62}$/.test(host) || /^[a-z0-9.-]+\.internal$/.test(host)
}

export function validateLocalLlmBaseUrl(value: string, allowlistInput: string): string {
  const url = new URL(value)
  if (!['http:', 'https:'].includes(url.protocol)) throw new Error('Local LLM URL must use HTTP(S)')
  if (url.username || url.password || url.search || url.hash) {
    throw new Error('Local LLM URL must not contain credentials, query, or fragment')
  }
  const host = normalizedHost(url.hostname)
  const allowedHosts = allowlistInput
    .split(',')
    .map((entry) => normalizedHost(entry.trim()))
    .filter(Boolean)
  if (allowedHosts.length === 0 || allowedHosts.some((entry) => !/^[a-z0-9.:-]+$/i.test(entry))) {
    throw new Error('LOCAL_LLM_ALLOWED_HOSTS must contain bare host names')
  }
  if (!allowedHosts.includes(host) || !isInternalLlmHost(host)) {
    throw new Error('Local LLM host is not an explicitly allowed internal host')
  }
  const path = url.pathname.replace(/\/+$/, '')
  if (path !== '/v1') throw new Error('Local LLM base URL must end in /v1')
  return `${url.protocol}//${url.host}/v1`
}

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
  let localLlmBaseUrl = env.LOCAL_LLM_BASE_URL
  if (env.ANTHROPIC_PROVIDER === 'local') {
    if (!env.LOCAL_LLM_BASE_URL || !env.LOCAL_LLM_MODEL || !env.LOCAL_LLM_ALLOWED_HOSTS) {
      throw new Error('Local LLM base URL, model, and host allowlist are required')
    }
    localLlmBaseUrl = validateLocalLlmBaseUrl(
      env.LOCAL_LLM_BASE_URL,
      env.LOCAL_LLM_ALLOWED_HOSTS,
    )
  }
  return {
    ...env,
    LOCAL_LLM_BASE_URL: localLlmBaseUrl,
    tenants: buildTenantRegistry(parseTenantConfig(env.TENANTS_JSON)),
  }
}
