import type { AgentInputItem, Session } from '@openai/agents';
import type { createClient } from 'redis';

const SESSION_TTL_SECONDS = 7 * 24 * 60 * 60;

export class RedisAgentSession implements Session {
  readonly #key: string;
  readonly #redis: ReturnType<typeof createClient>;
  readonly #sessionId: string;

  constructor(redis: ReturnType<typeof createClient>, conversationId: number) {
    this.#redis = redis;
    this.#sessionId = `chatwoot-conversation-${conversationId}`;
    this.#key = `agentbot:session:${conversationId}`;
  }

  async getSessionId(): Promise<string> {
    return this.#sessionId;
  }

  async getItems(limit?: number): Promise<AgentInputItem[]> {
    const serialized = await this.#redis.get(this.#key);
    const items = serialized ? (JSON.parse(serialized) as AgentInputItem[]) : [];
    return limit === undefined ? items : items.slice(-limit);
  }

  async addItems(items: AgentInputItem[]): Promise<void> {
    const current = await this.getItems();
    await this.#redis.set(this.#key, JSON.stringify([...current, ...items]), { EX: SESSION_TTL_SECONDS });
  }

  async popItem(): Promise<AgentInputItem | undefined> {
    const current = await this.getItems();
    const item = current.pop();
    if (current.length === 0) await this.#redis.del(this.#key);
    else await this.#redis.set(this.#key, JSON.stringify(current), { EX: SESSION_TTL_SECONDS });
    return item;
  }

  async clearSession(): Promise<void> {
    await this.#redis.del(this.#key);
  }
}
