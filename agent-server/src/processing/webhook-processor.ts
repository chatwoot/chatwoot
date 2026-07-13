import type { FastifyBaseLogger } from 'fastify';
import type { ReplyGenerator } from '../agent/reply-generator.js';
import type { ChatwootGateway } from '../chatwoot/client.js';
import type { ChatwootWebhookPayload } from '../chatwoot/types.js';
import type { ProcessingCoordination } from './coordination.js';

type WebhookProcessorOptions = {
  agentBotId: number;
  chatwoot: ChatwootGateway;
  coordination: ProcessingCoordination;
  replyGenerator: ReplyGenerator;
};

export interface WebhookProcessor {
  process(payload: ChatwootWebhookPayload, logger: FastifyBaseLogger): Promise<void>;
}

export class ChatwootWebhookProcessor implements WebhookProcessor {
  readonly #agentBotId: number;
  readonly #chatwoot: ChatwootGateway;
  readonly #coordination: ProcessingCoordination;
  readonly #replyGenerator: ReplyGenerator;

  constructor(options: WebhookProcessorOptions) {
    this.#agentBotId = options.agentBotId;
    this.#chatwoot = options.chatwoot;
    this.#coordination = options.coordination;
    this.#replyGenerator = options.replyGenerator;
  }

  async process(payload: ChatwootWebhookPayload, logger: FastifyBaseLogger): Promise<void> {
    const ignoredReason = this.#initialIgnoredReason(payload);
    if (ignoredReason) {
      logger.info({ event: 'message_decision', decision: 'ignore', reason: ignoredReason });
      return;
    }

    const messageId = payload.id!;
    const conversationId = payload.conversation!.id!;
    const lockToken = await this.#coordination.acquireConversation(conversationId);
    if (!lockToken) throw new Error(`Timed out acquiring conversation lock for ${conversationId}`);

    try {
      const claimed = await this.#coordination.claimMessage(messageId);
      if (!claimed) {
        logger.info({ event: 'message_decision', decision: 'ignore', reason: 'duplicate_message', conversationId, messageId });
        return;
      }

      try {
        const ownershipDecision = this.#ownershipDecision(payload);
        if (
          ownershipDecision === 'assigned_to_user' ||
          ownershipDecision === 'assigned_to_other_bot' ||
          ownershipDecision === 'unassigned_open'
        ) {
          logger.info({
            event: 'message_decision',
            decision: 'ignore',
            reason: ownershipDecision,
            conversationId,
            messageId
          });
          await this.#coordination.completeMessage(messageId);
          return;
        }

        if (ownershipDecision === 'claim') {
          logger.info({ event: 'message_decision', decision: 'claim', reason: 'unassigned', conversationId, messageId });
          await this.#chatwoot.assignConversation(conversationId);
          logger.info({ event: 'chatwoot_action', action: 'assign_agent_bot', status: 'success', conversationId });
        } else {
          logger.info({
            event: 'message_decision',
            decision: 'reply',
            reason: 'assigned_to_self',
            conversationId,
            messageId
          });
        }

        const reply = await this.#replyGenerator.generate({
          content: payload.content!.trim(),
          conversationId,
          logger,
          payload
        });
        const outgoingMessage = await this.#chatwoot.createMessage(conversationId, reply);
        logger.info({
          event: 'chatwoot_action',
          action: 'create_message',
          status: 'success',
          conversationId,
          outgoingMessageId: outgoingMessage.id
        });
        await this.#coordination.completeMessage(messageId);
      } catch (error) {
        await this.#coordination.releaseMessage(messageId);
        throw error;
      }
    } finally {
      await this.#coordination.releaseConversation(conversationId, lockToken);
    }
  }

  #initialIgnoredReason(payload: ChatwootWebhookPayload): string | null {
    if (payload.event !== 'message_created') return 'not_message_created';
    if (payload.message_type !== 'incoming') return 'not_incoming';
    if (payload.private) return 'private_message';
    if (!payload.id || !payload.conversation?.id || !payload.content?.trim()) return 'invalid_payload';
    if (!['pending', 'open'].includes(payload.conversation.status ?? '')) return 'conversation_not_active';
    return null;
  }

  #ownershipDecision(
    payload: ChatwootWebhookPayload
  ): 'claim' | 'reply' | 'assigned_to_user' | 'assigned_to_other_bot' | 'unassigned_open' {
    const assignee = payload.conversation?.meta?.assignee;
    const assigneeType = payload.conversation?.meta?.assignee_type;
    if (!assignee && !assigneeType) return payload.conversation?.status === 'pending' ? 'claim' : 'unassigned_open';
    if (assigneeType === 'AgentBot' && assignee?.id === this.#agentBotId) return 'reply';
    if (assigneeType === 'User') return 'assigned_to_user';
    return 'assigned_to_other_bot';
  }
}
