import type { FastifyBaseLogger } from 'fastify';
import { describe, expect, it } from 'vitest';
import type { ReplyGenerator } from '../src/agent/reply-generator.js';
import type { ChatwootGateway, CreatedMessage } from '../src/chatwoot/client.js';
import type { ChatwootWebhookPayload } from '../src/chatwoot/types.js';
import type { ProcessingCoordination } from '../src/processing/coordination.js';
import { ChatwootWebhookProcessor } from '../src/processing/webhook-processor.js';

class MemoryCoordination implements ProcessingCoordination {
  claimedMessages = new Set<number>();
  completedMessages = new Set<number>();

  async acquireConversation(conversationId: number): Promise<string> {
    return `lock-${conversationId}`;
  }

  async releaseConversation(): Promise<void> {}

  async claimMessage(messageId: number): Promise<boolean> {
    if (this.claimedMessages.has(messageId)) return false;
    this.claimedMessages.add(messageId);
    return true;
  }

  async completeMessage(messageId: number): Promise<void> {
    this.completedMessages.add(messageId);
  }

  async releaseMessage(messageId: number): Promise<void> {
    this.claimedMessages.delete(messageId);
  }
}

class FakeChatwoot implements ChatwootGateway {
  assignments: number[] = [];
  messages: { conversationId: number; content: string }[] = [];

  async assignConversation(conversationId: number): Promise<void> {
    this.assignments.push(conversationId);
  }

  async createMessage(conversationId: number, content: string): Promise<CreatedMessage> {
    this.messages.push({ conversationId, content });
    return { id: 900 + this.messages.length, content };
  }
}

const replyGenerator: ReplyGenerator = {
  async generate({ content }) {
    return `reply:${content}`;
  }
};

const logger = {
  info() {},
  error() {},
  warn() {},
  debug() {},
  fatal() {},
  trace() {},
  child() {
    return this;
  },
  level: 'silent',
  silent() {}
} as unknown as FastifyBaseLogger;

const incomingPayload = (overrides: Partial<ChatwootWebhookPayload> = {}): ChatwootWebhookPayload => ({
  event: 'message_created',
  id: 101,
  content: 'hello',
  message_type: 'incoming',
  private: false,
  conversation: {
    id: 42,
    status: 'pending',
    meta: { assignee: null, assignee_type: null }
  },
  ...overrides
});

const createProcessor = () => {
  const chatwoot = new FakeChatwoot();
  const coordination = new MemoryCoordination();
  const processor = new ChatwootWebhookProcessor({
    agentBotId: 7,
    chatwoot,
    coordination,
    replyGenerator
  });
  return { chatwoot, coordination, processor };
};

describe('ChatwootWebhookProcessor', () => {
  it('claims an unassigned pending conversation before replying', async () => {
    const { chatwoot, coordination, processor } = createProcessor();

    await processor.process(incomingPayload(), logger);

    expect(chatwoot.assignments).toEqual([42]);
    expect(chatwoot.messages).toEqual([{ conversationId: 42, content: 'reply:hello' }]);
    expect(coordination.completedMessages).toContain(101);
  });

  it('continues replying without reassignment when assigned to itself', async () => {
    const { chatwoot, processor } = createProcessor();
    const payload = incomingPayload({
      conversation: {
        id: 42,
        status: 'pending',
        meta: { assignee: { id: 7, type: 'agent_bot' }, assignee_type: 'AgentBot' }
      }
    });

    await processor.process(payload, logger);

    expect(chatwoot.assignments).toEqual([]);
    expect(chatwoot.messages).toHaveLength(1);
  });

  it('continues replying when Chatwoot opens a conversation assigned to itself', async () => {
    const { chatwoot, processor } = createProcessor();
    const payload = incomingPayload({
      conversation: {
        id: 42,
        status: 'open',
        meta: { assignee: { id: 7, type: 'agent_bot' }, assignee_type: 'AgentBot' }
      }
    });

    await processor.process(payload, logger);

    expect(chatwoot.assignments).toEqual([]);
    expect(chatwoot.messages).toHaveLength(1);
  });

  it('does not claim an unassigned open conversation', async () => {
    const { chatwoot, processor } = createProcessor();
    const payload = incomingPayload({
      conversation: {
        id: 42,
        status: 'open',
        meta: { assignee: null, assignee_type: null }
      }
    });

    await processor.process(payload, logger);

    expect(chatwoot.assignments).toEqual([]);
    expect(chatwoot.messages).toEqual([]);
  });

  it('does not reply when a user owns the conversation', async () => {
    const { chatwoot, processor } = createProcessor();
    const payload = incomingPayload({
      conversation: {
        id: 42,
        status: 'pending',
        meta: { assignee: { id: 9, type: 'user' }, assignee_type: 'User' }
      }
    });

    await processor.process(payload, logger);

    expect(chatwoot.assignments).toEqual([]);
    expect(chatwoot.messages).toEqual([]);
  });

  it('ignores outgoing AgentBot messages', async () => {
    const { chatwoot, processor } = createProcessor();

    await processor.process(incomingPayload({ message_type: 'outgoing' }), logger);

    expect(chatwoot.assignments).toEqual([]);
    expect(chatwoot.messages).toEqual([]);
  });

  it('does not process the same incoming message twice', async () => {
    const { chatwoot, processor } = createProcessor();
    const payload = incomingPayload();

    await processor.process(payload, logger);
    await processor.process(payload, logger);

    expect(chatwoot.messages).toHaveLength(1);
  });
});
