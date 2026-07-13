import { randomUUID } from 'node:crypto';
import { setTimeout as delay } from 'node:timers/promises';
import type { createClient } from 'redis';

type RedisClient = ReturnType<typeof createClient>;

export interface ProcessingCoordination {
  acquireConversation(conversationId: number): Promise<string | null>;
  releaseConversation(conversationId: number, lockToken: string): Promise<void>;
  claimMessage(messageId: number): Promise<boolean>;
  completeMessage(messageId: number): Promise<void>;
  releaseMessage(messageId: number): Promise<void>;
}

export class RedisProcessingCoordination implements ProcessingCoordination {
  readonly #redis: RedisClient;
  readonly #prefix: string;

  constructor(redis: RedisClient, prefix = 'chatwoot-agent') {
    this.#redis = redis;
    this.#prefix = prefix;
  }

  async acquireConversation(conversationId: number): Promise<string | null> {
    const key = this.#conversationKey(conversationId);
    const token = randomUUID();

    for (let attempt = 0; attempt < 50; attempt += 1) {
      const result = await this.#redis.set(key, token, { NX: true, PX: 30_000 });
      if (result === 'OK') return token;
      await delay(100);
    }

    return null;
  }

  async releaseConversation(conversationId: number, lockToken: string): Promise<void> {
    await this.#redis.eval(
      "if redis.call('get', KEYS[1]) == ARGV[1] then return redis.call('del', KEYS[1]) else return 0 end",
      { keys: [this.#conversationKey(conversationId)], arguments: [lockToken] }
    );
  }

  async claimMessage(messageId: number): Promise<boolean> {
    const result = await this.#redis.set(this.#messageKey(messageId), 'processing', { NX: true, EX: 60 });
    return result === 'OK';
  }

  async completeMessage(messageId: number): Promise<void> {
    await this.#redis.set(this.#messageKey(messageId), 'done', { EX: 24 * 60 * 60 });
  }

  async releaseMessage(messageId: number): Promise<void> {
    await this.#redis.del(this.#messageKey(messageId));
  }

  #conversationKey(conversationId: number): string {
    return `${this.#prefix}:conversation:${conversationId}:lock`;
  }

  #messageKey(messageId: number): string {
    return `${this.#prefix}:message:${messageId}`;
  }
}
