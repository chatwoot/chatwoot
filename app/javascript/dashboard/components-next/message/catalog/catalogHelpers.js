// Catalog products and orders from the WhatsApp connector (fazer-ai/chatwoot#996).
// Amounts arrive in thousandths of the currency's unit (price_1000, total_1000), and a
// price WhatsApp did not send is absent: it renders as nothing, never as zero.

const toIntlLocale = locale => (locale || 'en').replace('_', '-');

export const formatPrice = (amount1000, currency, locale) => {
  if (typeof amount1000 !== 'number' || !currency) return null;
  const value = amount1000 / 1000;
  try {
    return new Intl.NumberFormat(toIntlLocale(locale), {
      style: 'currency',
      currency,
    }).format(value);
  } catch {
    // A code Intl does not know still shows the amount with the code WhatsApp sent.
    return `${currency} ${value.toFixed(2)}`;
  }
};

// The connector sends thumbnails inline. Only an image data URI reaches an <img>.
export const toImageDataUri = value =>
  typeof value === 'string' && value.startsWith('data:image/') ? value : null;

// Item pictures and product pages come from WhatsApp: only well-formed http(s).
export const toHttpUrl = url => {
  if (typeof url !== 'string' || !url) return null;
  try {
    return ['http:', 'https:'].includes(new URL(url).protocol) ? url : null;
  } catch {
    return null;
  }
};

export const hasText = value =>
  typeof value === 'string' && value.trim() !== '';
