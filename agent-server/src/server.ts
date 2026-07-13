import Fastify, { LogController, type FastifyInstance } from 'fastify';
import type { AppConfig } from './config.js';
import type { ChatwootWebhookPayload } from './chatwoot/types.js';
import { verifyChatwootSignature } from './chatwoot/signature.js';
import { renderWidgetPage } from './widget-page.js';

declare module 'fastify' {
  interface FastifyRequest {
    rawBody?: string;
  }
}

const maskedPhoneSuffix = (phone?: string | null): string | undefined =>
  phone ? phone.replace(/\D/g, '').slice(-4) : undefined;

export const buildServer = (config: AppConfig): FastifyInstance => {
  const server = Fastify({
    logger: {
      level: config.LOG_LEVEL,
      redact: ['req.headers.api_access_token', 'req.headers.authorization']
    },
    logController: new LogController({ disableRequestLogging: true })
  });

  server.addContentTypeParser('application/json', { parseAs: 'string' }, (request, body, done) => {
    const rawBody = typeof body === 'string' ? body : body.toString('utf8');
    request.rawBody = rawBody;
    try {
      done(null, JSON.parse(rawBody));
    } catch (error) {
      done(error as Error);
    }
  });

  server.get('/healthz', async () => ({ status: 'ok' }));

  server.get('/', async (_request, reply) =>
    reply.type('text/html; charset=utf-8').send(renderWidgetPage(config))
  );

  server.post<{ Body: ChatwootWebhookPayload }>('/webhooks/chatwoot', async (request, reply) => {
    const deliveryId = request.headers['x-chatwoot-delivery'];
    const signature = request.headers['x-chatwoot-signature'];
    const timestamp = request.headers['x-chatwoot-timestamp'];

    if (
      config.CHATWOOT_WEBHOOK_SECRET &&
      !verifyChatwootSignature(
        request.rawBody ?? '',
        {
          signature: Array.isArray(signature) ? signature[0] : signature,
          timestamp: Array.isArray(timestamp) ? timestamp[0] : timestamp
        },
        config.CHATWOOT_WEBHOOK_SECRET
      )
    ) {
      request.log.warn({ event: 'webhook_rejected', reason: 'invalid_signature', deliveryId });
      return reply.code(401).send({ error: 'invalid_signature' });
    }

    const payload = request.body;
    request.log.info({
      event: 'webhook_received',
      deliveryId,
      chatwootEvent: payload.event,
      conversationId: payload.conversation?.id,
      messageId: payload.id,
      messageType: payload.message_type,
      private: payload.private,
      assigneeType: payload.conversation?.meta?.assignee_type,
      assigneeId: payload.conversation?.meta?.assignee?.id,
      senderIdentifierPresent: Boolean(payload.sender?.identifier),
      senderPhonePresent: Boolean(payload.sender?.phone_number),
      senderPhoneLast4: maskedPhoneSuffix(payload.sender?.phone_number)
    });

    return reply.code(204).send();
  });

  return server;
};
