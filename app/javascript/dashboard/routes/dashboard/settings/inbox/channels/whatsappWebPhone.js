export const WHATSAPP_WEB_PHONE_DIGITS = 11;

export const normalizeWhatsappWebPhone = value =>
  value
    .toString()
    .replace(/\D/g, '')
    .slice(0, WHATSAPP_WEB_PHONE_DIGITS);

export const isValidWhatsappWebPhone = value =>
  normalizeWhatsappWebPhone(value).length === WHATSAPP_WEB_PHONE_DIGITS;
