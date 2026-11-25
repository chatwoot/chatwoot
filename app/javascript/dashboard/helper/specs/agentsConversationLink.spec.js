import { createHash } from 'node:crypto';
import {
  agentsConsoleBase,
  agentsConversationUrl,
  parseAgentsWebhook,
  routeTokenHash,
} from '../agentsConversationLink';

const ref = { accountId: 3, conversationId: 42, inboxId: 9 };
const ROUTE_TOKEN = 'route-token';
const routeTokenSha256 = createHash('sha256').update(ROUTE_TOKEN).digest('hex');

describe('agentsConversationLink', () => {
  it('reads the install and the route token out of a fazer.ai agents webhook, keeping a path prefix', () => {
    expect(
      parseAgentsWebhook(
        'https://example.com/agents/api/v1/chatwoot/webhook/route-token'
      )
    ).toEqual({
      base: 'https://example.com/agents',
      routeToken: ROUTE_TOKEN,
    });
  });

  it('gives nothing for a bot that is not fazer.ai agents, an empty URL or one that does not parse', () => {
    expect(parseAgentsWebhook('https://bot.example.com/webhook')).toBeNull();
    expect(parseAgentsWebhook('')).toBeNull();
    expect(parseAgentsWebhook(undefined)).toBeNull();
    expect(
      parseAgentsWebhook('not a url /api/v1/chatwoot/webhook/t')
    ).toBeNull();
  });

  it('hashes the route token the way fazer.ai agents keys its bots', async () => {
    expect(await routeTokenHash(ROUTE_TOKEN)).toBe(routeTokenSha256);
  });

  it('gives no hash where the browser has no crypto.subtle (a dashboard over plain HTTP)', async () => {
    const real = globalThis.crypto;
    Object.defineProperty(globalThis, 'crypto', {
      value: {},
      configurable: true,
    });
    try {
      expect(await routeTokenHash(ROUTE_TOKEN)).toBeNull();
    } finally {
      Object.defineProperty(globalThis, 'crypto', {
        value: real,
        configurable: true,
      });
    }
  });

  it('links to the conversation with its inbox and the bot hash, never the token', () => {
    const url = agentsConversationUrl(
      'https://agents.example.com',
      routeTokenSha256,
      ref
    );
    expect(url).toBe(
      `https://agents.example.com/chatwoot/accounts/3/conversations/42?inbox=9&bot=${routeTokenSha256}`
    );
    expect(url).not.toContain(ROUTE_TOKEN);
  });

  it('leaves the bot out when there is no hash', () => {
    expect(agentsConversationUrl('https://agents.example.com', null, ref)).toBe(
      'https://agents.example.com/chatwoot/accounts/3/conversations/42?inbox=9'
    );
  });

  describe('agentsConsoleBase', () => {
    const WEBHOOK_BASE = 'http://10.40.10.20:3000';

    it('opens the console at the public address the bot carries, keeping port and path prefix', () => {
      expect(
        agentsConsoleBase('https://console.example.com', WEBHOOK_BASE)
      ).toBe('https://console.example.com');
      expect(
        agentsConsoleBase('https://console.example.com:8443/', WEBHOOK_BASE)
      ).toBe('https://console.example.com:8443');
      expect(
        agentsConsoleBase('http://example.com/agents/?x=1#top', WEBHOOK_BASE)
      ).toBe('http://example.com/agents');
    });

    it('keeps the webhook origin when the bot carries no public address, or one a link must not open', () => {
      [
        undefined,
        null,
        '',
        // eslint-disable-next-line no-script-url
        'javascript:alert(1)',
        'data:text/html,hi',
        'ftp://console.example.com',
        'console.example.com',
        42,
      ].forEach(consoleUrl => {
        expect(agentsConsoleBase(consoleUrl, WEBHOOK_BASE)).toBe(WEBHOOK_BASE);
      });
    });
  });
});
