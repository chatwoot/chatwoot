import { createHmac } from 'node:crypto';
import { afterEach, describe, expect, it } from 'vitest';
import type { AppConfig } from '../src/config.js';
import { buildServer } from '../src/server.js';

const config: AppConfig = {
  HOST: '127.0.0.1',
  PORT: 3400,
  LOG_LEVEL: 'silent',
  CHATWOOT_INTERNAL_URL: 'http://rails:3000',
  CHATWOOT_PUBLIC_URL: 'http://localhost:3300',
  CHATWOOT_WEBSITE_TOKEN: 'website-token',
  CHATWOOT_WEBHOOK_SECRET: 'test-secret',
  OPENAI_MODEL: 'gpt-5.6-luna',
  DEMO_CUSTOMER_IDENTIFIER: 'demo-customer-001',
  DEMO_CUSTOMER_NAME: 'Demo Customer',
  DEMO_CUSTOMER_EMAIL: 'demo@example.test',
  DEMO_CUSTOMER_PHONE: '+821012345678'
};

const servers: ReturnType<typeof buildServer>[] = [];

afterEach(async () => {
  await Promise.all(servers.splice(0).map(server => server.close()));
});

describe('server', () => {
  it('accepts a signed Chatwoot webhook', async () => {
    const server = buildServer(config);
    servers.push(server);
    const payload = JSON.stringify({
      event: 'message_created',
      id: 101,
      message_type: 'incoming',
      private: false,
      conversation: { id: 42, status: 'pending', meta: { assignee: null, assignee_type: null } },
      sender: { identifier: 'demo-customer-001', phone_number: '+821012345678' }
    });
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const signature = `sha256=${createHmac('sha256', config.CHATWOOT_WEBHOOK_SECRET!)
      .update(`${timestamp}.${payload}`)
      .digest('hex')}`;

    const response = await server.inject({
      method: 'POST',
      url: '/webhooks/chatwoot',
      payload,
      headers: {
        'content-type': 'application/json',
        'x-chatwoot-delivery': 'delivery-1',
        'x-chatwoot-timestamp': timestamp,
        'x-chatwoot-signature': signature
      }
    });

    expect(response.statusCode).toBe(204);
  });

  it('rejects a webhook with an invalid signature', async () => {
    const server = buildServer(config);
    servers.push(server);

    const response = await server.inject({
      method: 'POST',
      url: '/webhooks/chatwoot',
      payload: { event: 'message_created' },
      headers: {
        'x-chatwoot-timestamp': Math.floor(Date.now() / 1000).toString(),
        'x-chatwoot-signature': 'sha256=invalid'
      }
    });

    expect(response.statusCode).toBe(401);
    expect(response.json()).toEqual({ error: 'invalid_signature' });
  });

  it('serves a Widget page with the configured customer identity', async () => {
    const server = buildServer(config);
    servers.push(server);

    const response = await server.inject({ method: 'GET', url: '/' });

    expect(response.statusCode).toBe(200);
    expect(response.body).toContain('demo-customer-001');
    expect(response.body).toContain('phone_number');
    expect(response.body).toContain('website-token');
  });
});
