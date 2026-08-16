import type { TenantConfig } from './config.js'

export class ChatwootApiError extends Error {
  constructor(
    message: string,
    readonly status: number,
  ) {
    super(message)
    this.name = 'ChatwootApiError'
  }
}

export interface ChatwootPort {
  sendMessage(tenant: TenantConfig, conversationId: number, content: string, deliveryId: number): Promise<void>
  handoff(tenant: TenantConfig, conversationId: number): Promise<void>
}

export class ChatwootClient implements ChatwootPort {
  private readonly baseUrl: string

  constructor(
    baseUrl: string,
    private readonly request: typeof fetch = fetch,
  ) {
    this.baseUrl = baseUrl.replace(/\/$/, '')
  }

  async sendMessage(
    tenant: TenantConfig,
    conversationId: number,
    content: string,
    deliveryId: number,
  ): Promise<void> {
    await this.post(tenant, conversationId, 'messages', {
      content,
      message_type: 'outgoing',
      content_attributes: { myinvest_agent_delivery_id: String(deliveryId) },
    })
  }

  async handoff(
    tenant: TenantConfig,
    conversationId: number,
  ): Promise<void> {
    await this.post(tenant, conversationId, 'toggle_status', { status: 'open' })
  }

  private async post(
    tenant: TenantConfig,
    conversationId: number,
    action: string,
    body: Record<string, unknown>,
  ): Promise<void> {
    const path = `/api/v1/accounts/${tenant.accountId}/conversations/${conversationId}/${action}`
    await this.fetchResponse(tenant, path, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(body),
    })
  }

  private async fetchResponse(
    tenant: TenantConfig,
    path: string,
    init: RequestInit,
  ): Promise<Response> {
    let response: Response
    try {
      response = await this.request(`${this.baseUrl}${path}`, {
        ...init,
        headers: {
          ...init.headers,
          api_access_token: tenant.agentBotToken,
          'x-forwarded-proto': 'https',
        },
        signal: AbortSignal.timeout(10_000),
      })
    } catch {
      throw new ChatwootApiError(`Chatwoot request ${path} failed`, 0)
    }
    if (!response.ok) {
      throw new ChatwootApiError(`Chatwoot request ${path} returned ${response.status}`, response.status)
    }
    return response
  }
}
