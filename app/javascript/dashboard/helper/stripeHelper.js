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

export const STRIPE_STATUS_COLORS = {
  active: 'teal',
  paid: 'teal',
  trialing: 'blue',
  open: 'amber',
  past_due: 'ruby',
  unpaid: 'ruby',
  uncollectible: 'ruby',
};

export const formatStripeAmount = (
  amount,
  currency,
  { preservePrecision = false } = {}
) => {
  const code = currency.toUpperCase();
  let digits = 2;
  if (ZERO_DECIMAL_CURRENCIES.includes(code)) digits = 0;
  if (THREE_DECIMAL_CURRENCIES.includes(code)) digits = 3;
  const fractionalDigits = preservePrecision
    ? (String(amount).split('.')[1] || '').replace(/0+$/, '').length
    : 0;
  return new Intl.NumberFormat(undefined, {
    style: 'currency',
    currency: code,
    minimumFractionDigits: digits,
    maximumFractionDigits: digits + fractionalDigits,
  }).format(Number(amount) / 10 ** digits);
};
