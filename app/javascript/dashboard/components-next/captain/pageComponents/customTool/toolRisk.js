// Hints for admins about custom tools that may need email verification. These are advice only and never block a save.

export const RISK_WEIGHTS = {
  WRITE_METHOD: 10,
  DELETE_METHOD: 15,
  CREDENTIALS: 5,
  EMAIL_PARAM: 5,
  ID_PARAM: 5,
  MONEY_WORDS: 5,
  PERSONAL_DATA_WORDS: 5,
  PRIVATE_API_HOST: 5,
};

export const RISK_LEVELS = { NONE: 'none', MEDIUM: 'medium', HIGH: 'high' };
export const MEDIUM_RISK_SCORE = 10;
export const HIGH_RISK_SCORE = 15;

const WRITE_METHODS = ['POST', 'PUT', 'PATCH'];
const ID_WORDS = ['id', 'number', 'account', 'customer', 'order', 'invoice'];
const MONEY_WORDS = [
  'payment',
  'payments',
  'billing',
  'invoice',
  'invoices',
  'subscription',
  'subscriptions',
  'charge',
  'charges',
  'refund',
  'refunds',
  'card',
  'cards',
  'plan',
  'plans',
];
const PERSONAL_DATA_WORDS = [
  'customer',
  'customers',
  'account',
  'accounts',
  'profile',
  'profiles',
  'address',
  'phone',
  'user',
  'users',
  'contact',
  'contacts',
  'person',
  'people',
];
const PRIVATE_API_HOSTS = [
  'api.stripe.com',
  'api.attio.com',
  'api.hubapi.com',
  'api.shopify.com',
];

// Splits text into lowercase words, so "customer_id", "customerId" and "Customer ID" all give "customer" and "id"
const words = text =>
  (text || '')
    .replace(/([a-z0-9])([A-Z])/g, '$1 $2')
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter(Boolean);

const hasAnyWord = (text, list) =>
  words(text).some(word => list.includes(word));

const modelFilledParams = tool =>
  (tool.param_schema || []).filter(param => !param.source);

// "email", "customer_email", "customerEmail" and "e_mail" all count, as does a description that mentions an email
export const isEmailLikeParam = param => {
  const nameWords = words(param.name);
  return (
    nameWords.includes('email') ||
    nameWords.join('_').includes('e_mail') ||
    words(param.description).includes('email')
  );
};

export const isIdLikeParam = param => hasAnyWord(param.name, ID_WORDS);

const urlHost = url => {
  try {
    return new URL(url).host;
  } catch {
    return '';
  }
};

const hasCredentials = tool =>
  (tool.auth_type && tool.auth_type !== 'none') ||
  Object.keys(tool.headers || {}).length > 0;

export const toolRiskScore = tool => {
  const params = modelFilledParams(tool);
  const text = [tool.title, tool.description, tool.endpoint_url].join(' ');
  const signals = [
    [WRITE_METHODS.includes(tool.http_method), RISK_WEIGHTS.WRITE_METHOD],
    [tool.http_method === 'DELETE', RISK_WEIGHTS.DELETE_METHOD],
    [hasCredentials(tool), RISK_WEIGHTS.CREDENTIALS],
    [params.some(isEmailLikeParam), RISK_WEIGHTS.EMAIL_PARAM],
    [params.some(isIdLikeParam), RISK_WEIGHTS.ID_PARAM],
    [hasAnyWord(text, MONEY_WORDS), RISK_WEIGHTS.MONEY_WORDS],
    [hasAnyWord(text, PERSONAL_DATA_WORDS), RISK_WEIGHTS.PERSONAL_DATA_WORDS],
    [
      PRIVATE_API_HOSTS.includes(urlHost(tool.endpoint_url)),
      RISK_WEIGHTS.PRIVATE_API_HOST,
    ],
  ];
  return signals.reduce(
    (score, [matches, weight]) => (matches ? score + weight : score),
    0
  );
};

export const toolRiskLevel = tool => {
  const score = toolRiskScore(tool);
  if (score >= HIGH_RISK_SCORE) return RISK_LEVELS.HIGH;
  if (score >= MEDIUM_RISK_SCORE) return RISK_LEVELS.MEDIUM;
  return RISK_LEVELS.NONE;
};
