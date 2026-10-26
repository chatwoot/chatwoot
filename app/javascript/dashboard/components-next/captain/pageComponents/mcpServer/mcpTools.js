// Parameter sources, as the API stores them
export const PARAM_SOURCES = {
  MODEL: 'model',
  VERIFIED_EMAIL: 'verified.email',
  FIXED: 'fixed',
};

// How a server asks to be signed in to, as the API reports it
export const AUTH_TYPES = { NONE: 'none', OAUTH: 'oauth', TOKEN: 'token' };

// Remote MCP servers with one fixed URL, so picking one always fills a URL that works
export const POPULAR_SERVERS = [
  { name: 'PayPal', url: 'https://mcp.paypal.com/mcp' },
  { name: 'HubSpot', url: 'https://mcp.hubspot.com' },
  { name: 'Calendly', url: 'https://mcp.calendly.com' },
  { name: 'Cal.com', url: 'https://mcp.cal.com/mcp' },
  { name: 'Notion', url: 'https://mcp.notion.com/mcp' },
  { name: 'Supabase', url: 'https://mcp.supabase.com/mcp' },
];

// The URL field starts with this, since every MCP server Captain connects to uses HTTPS
export const URL_PREFIX = 'https://';

const DIGEST_PREFIX = 'sha256:';
const FINGERPRINT_LENGTH = 8;
const EMAIL_PARAM_PATTERN = /email/i;
const ID_PARAM_PATTERN = /(^id$|_id$|Id$)/;

export const fingerprintLabel = digest =>
  (digest || '').replace(DIGEST_PREFIX, '').slice(0, FINGERPRINT_LENGTH);

export const isEmailParam = name => EMAIL_PARAM_PATTERN.test(name);
export const isIdParam = name => ID_PARAM_PATTERN.test(name);

// The parameters of a JSON schema, in order, with whether each one is required
export const schemaParams = schema => {
  const required = schema?.required || [];
  return Object.entries(schema?.properties || {}).map(([name, property]) => ({
    name,
    type: property.type || 'string',
    description: property.description || '',
    required: required.includes(name),
  }));
};

// The API keeps only Chatwoot-filled parameters. Captain fills every other one.
export const sourceOf = (paramSources, name) =>
  paramSources?.[name]?.source || PARAM_SOURCES.MODEL;

export const usesVerifiedEmail = paramSources =>
  Object.values(paramSources || {}).some(
    entry => entry.source === PARAM_SOURCES.VERIFIED_EMAIL
  );

export const requiresVerification = ({ paramSources, settings }) =>
  settings?.requires_email_verification === true ||
  usesVerifiedEmail(paramSources);
