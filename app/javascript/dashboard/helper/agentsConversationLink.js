// An inbox whose agent bot delivers to fazer.ai agents has an outgoing URL ending in this path plus a
// route token. The link is built from what comes before the path, so the token never leaves here.
const AGENTS_WEBHOOK_PATH = '/api/v1/chatwoot/webhook/';

export const parseAgentsWebhook = outgoingUrl => {
  if (!outgoingUrl) return null;
  let url;
  try {
    url = new URL(outgoingUrl);
  } catch {
    return null;
  }
  const at = url.pathname.indexOf(AGENTS_WEBHOOK_PATH);
  if (at === -1) return null;
  return {
    base: `${url.origin}${url.pathname.slice(0, at)}`,
    routeToken: url.pathname.slice(at + AGENTS_WEBHOOK_PATH.length),
  };
};

// The address Chatwoot calls the agents on can be private (fazer-ai/agents#1687), so the agents
// writes its public console address on the bot as `bot_config.console_url`. It is admin-editable
// and ends up in `window.open`, so only an http(s) URL replaces the webhook origin.
const LINKABLE_PROTOCOLS = ['http:', 'https:'];

export const agentsConsoleBase = (consoleUrl, webhookBase) => {
  let url;
  try {
    url = new URL(consoleUrl);
  } catch {
    return webhookBase;
  }
  if (!LINKABLE_PROTOCOLS.includes(url.protocol)) return webhookBase;
  return `${url.origin}${url.pathname.replace(/\/+$/, '')}`;
};

// fazer.ai agents keys each bot by the SHA-256 of its route token, so the hash names the Chatwoot
// server without the token travelling. `crypto.subtle` exists only in a secure context: a dashboard
// served over plain HTTP gets no hash, and its link falls back to account and inbox.
export const routeTokenHash = async routeToken => {
  if (!routeToken || !globalThis.crypto?.subtle) return null;
  const digest = await globalThis.crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(routeToken)
  );
  return [...new Uint8Array(digest)]
    .map(byte => byte.toString(16).padStart(2, '0'))
    .join('');
};

export const agentsConversationUrl = (
  base,
  botHash,
  { accountId, conversationId, inboxId }
) => {
  const bot = botHash ? `&bot=${botHash}` : '';
  return `${base}/chatwoot/accounts/${accountId}/conversations/${conversationId}?inbox=${inboxId}${bot}`;
};
