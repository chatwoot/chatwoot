// Parameter sources, as the API stores them
export const PARAM_SOURCES = {
  MODEL: 'model',
  VERIFIED_EMAIL: 'verified.email',
  FIXED: 'fixed',
};

// Icons for the suggested servers. Services without a brand icon in the icon sets use a generic one.
export const SUGGESTION_ICONS = {
  shopify: 'i-logos-shopify',
  stripe: 'i-logos-stripe',
  paypal: 'i-logos-paypal',
  hubspot: 'i-logos-hubspot',
  calendly: 'i-lucide-calendar-check',
  cal_com: 'i-lucide-calendar-days',
  notion: 'i-logos-notion-icon',
  supabase: 'i-logos-supabase-icon',
  n8n: 'i-lucide-workflow',
  zapier: 'i-logos-zapier-icon',
  make: 'i-lucide-workflow',
};
export const DEFAULT_SUGGESTION_ICON = 'i-lucide-server';
// The suggestions shown before "Show all"
export const VISIBLE_SUGGESTIONS = 6;
// The part of a URL template the admin fills in, such as the Shopify store name
export const STORE_PLACEHOLDER = '{store}';

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
