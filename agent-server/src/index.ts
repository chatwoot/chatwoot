import { createClient } from 'redis';
import { EchoReplyGenerator } from './agent/reply-generator.js';
import { ChatwootClient } from './chatwoot/client.js';
import { loadConfig } from './config.js';
import { RedisProcessingCoordination } from './processing/coordination.js';
import { ChatwootWebhookProcessor, type WebhookProcessor } from './processing/webhook-processor.js';
import { buildServer } from './server.js';

const config = loadConfig();
const processorConfiguration = {
  accountId: config.CHATWOOT_ACCOUNT_ID,
  agentBotId: config.CHATWOOT_AGENT_BOT_ID,
  accessToken: config.CHATWOOT_AGENT_BOT_TOKEN,
  redisUrl: config.REDIS_URL
};

const processorEnabled = Object.values(processorConfiguration).every(value => value !== undefined);
const redis = processorEnabled ? createClient({ url: config.REDIS_URL }) : undefined;
let webhookProcessor: WebhookProcessor | undefined;

if (redis && config.CHATWOOT_ACCOUNT_ID && config.CHATWOOT_AGENT_BOT_ID && config.CHATWOOT_AGENT_BOT_TOKEN) {
  await redis.connect();
  webhookProcessor = new ChatwootWebhookProcessor({
    agentBotId: config.CHATWOOT_AGENT_BOT_ID,
    chatwoot: new ChatwootClient({
      baseUrl: config.CHATWOOT_INTERNAL_URL,
      accountId: config.CHATWOOT_ACCOUNT_ID,
      agentBotId: config.CHATWOOT_AGENT_BOT_ID,
      accessToken: config.CHATWOOT_AGENT_BOT_TOKEN
    }),
    coordination: new RedisProcessingCoordination(redis),
    replyGenerator: new EchoReplyGenerator()
  });
}

const server = buildServer(config, { webhookProcessor });
server.log.info({ event: 'agent_processing_configured', enabled: processorEnabled });

const shutdown = async (signal: string): Promise<void> => {
  server.log.info({ event: 'server_shutdown', signal });
  await server.close();
  if (redis?.isOpen) await redis.close();
  process.exit(0);
};

process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));

try {
  await server.listen({ host: config.HOST, port: config.PORT });
} catch (error) {
  server.log.error(error);
  process.exit(1);
}
