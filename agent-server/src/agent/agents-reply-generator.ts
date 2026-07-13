import { Agent, run, setTracingDisabled } from '@openai/agents';
import type { createClient } from 'redis';
import { SUPPORT_AGENT_PROMPT } from './prompt.js';
import { RedisAgentSession } from './redis-session.js';
import { createRplsMockTools, type SupportAgentContext } from './rpls-mock-tools.js';
import type { ReplyGenerator, ReplyRequest } from './reply-generator.js';

type AgentsReplyGeneratorOptions = {
  model: string;
  redis: ReturnType<typeof createClient>;
};

export class AgentsReplyGenerator implements ReplyGenerator {
  readonly #agent: Agent<SupportAgentContext>;
  readonly #redis: ReturnType<typeof createClient>;

  constructor(options: AgentsReplyGeneratorOptions) {
    setTracingDisabled(true);
    this.#redis = options.redis;
    this.#agent = new Agent<SupportAgentContext>({
      name: 'Queenit Chatwoot Support Agent',
      instructions: SUPPORT_AGENT_PROMPT,
      model: options.model,
      tools: createRplsMockTools()
    });
  }

  async generate(request: ReplyRequest): Promise<string> {
    const customerPhone = request.payload.sender?.phone_number;
    if (!customerPhone) return '주문 확인을 위해 위젯에 등록된 휴대폰 번호가 필요합니다.';

    const context: SupportAgentContext = {
      conversationId: request.conversationId,
      customerPhone,
      logger: request.logger,
      ordersRead: false
    };
    const result = await run(this.#agent, request.content, {
      context,
      maxTurns: 6,
      session: new RedisAgentSession(this.#redis, request.conversationId)
    });
    const output = result.finalOutput?.trim();
    if (!output) throw new Error('Agent completed without a text response');

    request.logger.info({
      event: 'agent_run_completed',
      conversationId: request.conversationId,
      model: this.#agent.model,
      toolUsed: context.ordersRead,
      outputLength: output.length
    });
    return output;
  }
}
