// Single source of truth for billing currencies on the frontend.
// Adding a currency = one entry in BILLING_CURRENCY_CONFIG, add the code to
// SUPPORTED_BILLING_CURRENCIES, and add its label key under
// BILLING_SETTINGS.CURRENCY.OPTIONS in the locale files.

export const DEFAULT_BILLING_CURRENCY = 'usd';

// Order here drives the order of the currency toggle in the UI.
export const SUPPORTED_BILLING_CURRENCIES = ['usd', 'brl'];

export const BILLING_CURRENCY_CONFIG = {
  usd: {
    code: 'usd',
    intlLocale: 'en-US',
    i18nLabelKey: 'BILLING_SETTINGS.CURRENCY.OPTIONS.USD',
  },
  brl: {
    code: 'brl',
    intlLocale: 'pt-BR',
    i18nLabelKey: 'BILLING_SETTINGS.CURRENCY.OPTIONS.BRL',
  },
};

export const getCurrencyConfig = code =>
  BILLING_CURRENCY_CONFIG[(code || DEFAULT_BILLING_CURRENCY).toLowerCase()] ||
  BILLING_CURRENCY_CONFIG[DEFAULT_BILLING_CURRENCY];

export const formatCurrencyAmount = (amount, code, options = {}) => {
  const { intlLocale, code: currencyCode } = getCurrencyConfig(code);
  return new Intl.NumberFormat(intlLocale, {
    style: 'currency',
    currency: currencyCode.toUpperCase(),
    ...options,
  }).format(amount);
};

// Free trial: the in-app banner turns urgent this many days before the trial ends.
export const TRIAL_ENDING_SOON_DAYS = 3;

export const RECOMMENDED_TRIAL_PLAN = 'business';

// What each paid plan unlocks over the one below it, keyed by lowercased plan name.
export const TRIAL_PLAN_FEATURES = {
  startups: [
    'BILLING_SETTINGS.TRIAL.PLANS.STARTUPS.CHANNELS',
    'BILLING_SETTINGS.TRIAL.PLANS.STARTUPS.CAPTAIN',
    'BILLING_SETTINGS.TRIAL.PLANS.STARTUPS.HELP_CENTER',
    'BILLING_SETTINGS.TRIAL.PLANS.STARTUPS.API',
  ],
  business: [
    'BILLING_SETTINGS.TRIAL.PLANS.BUSINESS.EVERYTHING',
    'BILLING_SETTINGS.TRIAL.PLANS.BUSINESS.SLA',
    'BILLING_SETTINGS.TRIAL.PLANS.BUSINESS.ROLES',
    'BILLING_SETTINGS.TRIAL.PLANS.BUSINESS.ASSIGNMENT',
  ],
  enterprise: [
    'BILLING_SETTINGS.TRIAL.PLANS.ENTERPRISE.EVERYTHING',
    'BILLING_SETTINGS.TRIAL.PLANS.ENTERPRISE.SSO',
    'BILLING_SETTINGS.TRIAL.PLANS.ENTERPRISE.AUDIT_LOGS',
    'BILLING_SETTINGS.TRIAL.PLANS.ENTERPRISE.BRANDING',
  ],
};
