export type CreatedMessage = {
  id: number;
  content?: string;
};

export interface ChatwootGateway {
  assignConversation(conversationId: number): Promise<void>;
  createMessage(conversationId: number, content: string): Promise<CreatedMessage>;
}

type ChatwootClientOptions = {
  baseUrl: string;
  accountId: number;
  agentBotId: number;
  accessToken: string;
};

export class ChatwootClient implements ChatwootGateway {
  readonly #baseUrl: string;
  readonly #accountId: number;
  readonly #agentBotId: number;
  readonly #accessToken: string;

  constructor(options: ChatwootClientOptions) {
    this.#baseUrl = options.baseUrl.replace(/\/$/, '');
    this.#accountId = options.accountId;
    this.#agentBotId = options.agentBotId;
    this.#accessToken = options.accessToken;
  }

  async assignConversation(conversationId: number): Promise<void> {
    await this.#request(`/api/v1/accounts/${this.#accountId}/conversations/${conversationId}/assignments`, {
      method: 'POST',
      body: JSON.stringify({ assignee_id: this.#agentBotId, assignee_type: 'AgentBot' })
    });
  }

  async createMessage(conversationId: number, content: string): Promise<CreatedMessage> {
    const response = await this.#request(
      `/api/v1/accounts/${this.#accountId}/conversations/${conversationId}/messages`,
      {
        method: 'POST',
        body: JSON.stringify({ content, message_type: 'outgoing', private: false })
      }
    );

    const message = response as Partial<CreatedMessage>;
    if (typeof message.id !== 'number') throw new Error('Chatwoot create message response did not include an id');
    return message as CreatedMessage;
  }

  async #request(path: string, init: RequestInit): Promise<unknown> {
    const response = await fetch(`${this.#baseUrl}${path}`, {
      ...init,
      headers: {
        'content-type': 'application/json',
        api_access_token: this.#accessToken
      },
      signal: AbortSignal.timeout(10_000)
    });

    const body = await response.text();
    if (!response.ok) {
      throw new Error(`Chatwoot API ${init.method} ${path} failed with ${response.status}: ${body.slice(0, 300)}`);
    }

    return body ? JSON.parse(body) : null;
  }
}
