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
