// Stripe API units are independent of the locale's display precision.
const ZERO_DECIMAL_CURRENCIES = [
  'BIF',
  'CLP',
  'DJF',
  'GNF',
  'JPY',
  'KMF',
  'KRW',
  'MGA',
  'PYG',
  'RWF',
  'VND',
  'VUV',
  'XAF',
  'XOF',
  'XPF',
];
const THREE_DECIMAL_CURRENCIES = ['BHD', 'JOD', 'KWD', 'OMR', 'TND'];

export const formatStripeAmount = (amount, currency) => {
  const code = currency.toUpperCase();
  let digits = 2;
  if (ZERO_DECIMAL_CURRENCIES.includes(code)) digits = 0;
  if (THREE_DECIMAL_CURRENCIES.includes(code)) digits = 3;
  return new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: code,
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  }).format(Number(amount) / 10 ** digits);
};
