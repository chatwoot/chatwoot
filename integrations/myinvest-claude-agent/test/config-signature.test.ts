import { createHmac } from 'node:crypto'
import { describe, expect, it } from 'vitest'
import {
  buildTenantRegistry,
  loadConfig,
  parseTenantConfig,
  validateLocalLlmBaseUrl,
} from '../src/config.js'
import { verifyChatwootSignature } from '../src/webhook/signature.js'
import { tenants } from './fixtures.js'

describe('tenant configuration', () => {
  it('requires three independent tenants, accounts, and credentials', () => {
    const registry = buildTenantRegistry(tenants)
    expect(registry.requireByAccountId(202).key).toBe('new_academy')
    expect(() => registry.requireByAccountId(999)).toThrow(/unknown chatwoot account/i)
    expect(() => parseTenantConfig(JSON.stringify(tenants.slice(0, 2)))).toThrow(/exactly/i)
    expect(() => buildTenantRegistry([tenants[0]!, { ...tenants[1]!, accountId: 101 }, tenants[2]!])).toThrow(/account/i)
    expect(() => buildTenantRegistry([tenants[0]!, { ...tenants[1]!, agentBotToken: tenants[0]!.agentBotToken }, tenants[2]!])).toThrow(/credential/i)
  })

  it('allows deterministic Claude output only in explicit local smoke mode', () => {
    const environment = {
      DATABASE_URL: 'postgresql://example.invalid/agent',
      REDIS_URL: 'redis://example.invalid/1',
      CHATWOOT_BASE_URL: 'https://support.example.invalid',
      TENANTS_JSON: JSON.stringify(tenants),
      ANTHROPIC_PROVIDER: 'bedrock',
      LOCAL_FAKE_CLAUDE_ANSWER: 'local only',
    }
    expect(() => loadConfig(environment)).toThrow(/LOCAL_SMOKE/)
    expect(loadConfig({ ...environment, LOCAL_SMOKE: 'true' }).LOCAL_FAKE_CLAUDE_ANSWER).toBe(
      'local only',
    )
  })

  it('normalizes compose-provided empty optional local fields for non-local providers', () => {
    const config = loadConfig({
      DATABASE_URL: 'postgresql://example.invalid/agent',
      REDIS_URL: 'redis://example.invalid/1',
      CHATWOOT_BASE_URL: 'https://support.example.invalid',
      TENANTS_JSON: JSON.stringify(tenants),
      ANTHROPIC_PROVIDER: 'bedrock',
      LOCAL_LLM_BASE_URL: '',
      LOCAL_LLM_MODEL: '',
      LOCAL_LLM_ALLOWED_HOSTS: '',
      LOCAL_LLM_API_KEY: '',
    })
    expect(config.LOCAL_LLM_BASE_URL).toBeUndefined()
    expect(config.LOCAL_LLM_MODEL).toBeUndefined()
    expect(config.LOCAL_LLM_ALLOWED_HOSTS).toBeUndefined()
    expect(config.LOCAL_LLM_API_KEY).toBeUndefined()
    expect(() => loadConfig({
      ...{
        DATABASE_URL: 'postgresql://example.invalid/agent',
        REDIS_URL: 'redis://example.invalid/1',
        CHATWOOT_BASE_URL: 'https://support.example.invalid',
        TENANTS_JSON: JSON.stringify(tenants),
      },
      ANTHROPIC_PROVIDER: 'local',
      LOCAL_LLM_BASE_URL: '',
      LOCAL_LLM_MODEL: '',
      LOCAL_LLM_ALLOWED_HOSTS: '',
    })).toThrow(/required/i)
  })

  it('allows a local provider only on an explicit internal host and fixed v1 path', () => {
    const environment = {
      DATABASE_URL: 'postgresql://example.invalid/agent',
      REDIS_URL: 'redis://example.invalid/1',
      CHATWOOT_BASE_URL: 'https://support.example.invalid',
      TENANTS_JSON: JSON.stringify(tenants),
      ANTHROPIC_PROVIDER: 'local',
      LOCAL_LLM_BASE_URL: 'http://local-llm:8000/v1/',
      LOCAL_LLM_MODEL: 'local-model',
      LOCAL_LLM_ALLOWED_HOSTS: 'local-llm',
    }
    expect(loadConfig(environment).LOCAL_LLM_BASE_URL).toBe('http://local-llm:8000/v1')
    expect(validateLocalLlmBaseUrl('http://10.100.24.3:8000/v1', '10.100.24.3'))
      .toBe('http://10.100.24.3:8000/v1')

    for (const [url, hosts] of [
      ['http://example.com/v1', 'example.com'],
      ['http://169.254.169.254/v1', '169.254.169.254'],
      ['http://local-llm:8000/v1', 'other-service'],
      ['http://user:password@local-llm:8000/v1', 'local-llm'],
      ['http://local-llm:8000/admin', 'local-llm'],
    ]) {
      expect(() => validateLocalLlmBaseUrl(url!, hosts!)).toThrow()
    }
  })
})

describe('Chatwoot signature verification', () => {
  const body = '{"event":"message_created","content":"ä"}'
  const secret = 'a-production-length-webhook-secret'
  const nowMs = 1_800_000_000_000
  const timestamp = Math.floor(nowMs / 1000).toString()
  const sign = (value: string) => `sha256=${createHmac('sha256', secret).update(value).digest('hex')}`

  it('accepts only timestamp-dot-raw-body HMAC inside the replay window', () => {
    expect(() => verifyChatwootSignature({ rawBody: body, secret, timestamp, signature: sign(`${timestamp}.${body}`), nowMs, replayWindowSeconds: 300 })).not.toThrow()
    expect(() => verifyChatwootSignature({ rawBody: `${body} `, secret, timestamp, signature: sign(`${timestamp}.${body}`), nowMs, replayWindowSeconds: 300 })).toThrow(/signature/i)
    expect(() => verifyChatwootSignature({ rawBody: body, secret, timestamp: String(Number(timestamp) - 301), signature: sign(`${Number(timestamp) - 301}.${body}`), nowMs, replayWindowSeconds: 300 })).toThrow(/replay window/i)
  })
})
