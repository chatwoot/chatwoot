export const INBOX_TYPES = {
  WEB: 'Channel::WebWidget',
  FB: 'Channel::FacebookPage',
  TWITTER: 'Channel::TwitterProfile',
  TWILIO: 'Channel::TwilioSms',
  WHATSAPP: 'Channel::Whatsapp',
  API: 'Channel::Api',
  EMAIL: 'Channel::Email',
  TELEGRAM: 'Channel::Telegram',
  LINE: 'Channel::Line',
  SMS: 'Channel::Sms',
  INSTAGRAM: 'Channel::Instagram',
};

const INBOX_ICON_MAP_FILL = {
  [INBOX_TYPES.WEB]: 'i-ri-global-fill',
  [INBOX_TYPES.FB]: 'i-ri-messenger-fill',
  [INBOX_TYPES.TWITTER]: 'i-ri-twitter-x-fill',
  [INBOX_TYPES.WHATSAPP]: 'i-ri-whatsapp-fill',
  [INBOX_TYPES.API]: 'i-ri-cloudy-fill',
  [INBOX_TYPES.EMAIL]: 'i-ri-mail-fill',
  [INBOX_TYPES.TELEGRAM]: 'i-ri-telegram-fill',
  [INBOX_TYPES.LINE]: 'i-ri-line-fill',
  [INBOX_TYPES.INSTAGRAM]: 'i-ri-instagram-fill',
};

const DEFAULT_ICON_FILL = 'i-ri-chat-1-fill';

const INBOX_ICON_MAP_LINE = {
  [INBOX_TYPES.WEB]: 'i-ri-global-line',
  [INBOX_TYPES.FB]: 'i-ri-messenger-line',
  [INBOX_TYPES.TWITTER]: 'i-ri-twitter-x-line',
  [INBOX_TYPES.WHATSAPP]: 'i-ri-whatsapp-line',
  [INBOX_TYPES.API]: 'i-ri-cloudy-line',
  [INBOX_TYPES.EMAIL]: 'i-ri-mail-line',
  [INBOX_TYPES.TELEGRAM]: 'i-ri-telegram-line',
  [INBOX_TYPES.LINE]: 'i-ri-line-line',
  [INBOX_TYPES.INSTAGRAM]: 'i-ri-instagram-line',
};

const DEFAULT_ICON_LINE = 'i-ri-chat-1-line';

export const getInboxSource = (type, phoneNumber, inbox) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return inbox.website_url || '';

    case INBOX_TYPES.TWILIO:
    case INBOX_TYPES.WHATSAPP:
      return phoneNumber || '';

    case INBOX_TYPES.EMAIL:
      return inbox.email || '';

    default:
      return '';
  }
};
export const getReadableInboxByType = (type, phoneNumber) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return 'livechat';

    case INBOX_TYPES.FB:
      return 'facebook';

    case INBOX_TYPES.TWITTER:
      return 'twitter';

    case INBOX_TYPES.TWILIO:
      return phoneNumber?.startsWith('whatsapp') ? 'whatsapp' : 'sms';

    case INBOX_TYPES.WHATSAPP:
      return 'whatsapp';

    case INBOX_TYPES.API:
      return 'api';

    case INBOX_TYPES.EMAIL:
      return 'email';

    case INBOX_TYPES.TELEGRAM:
      return 'telegram';

    case INBOX_TYPES.LINE:
      return 'line';

    default:
      return 'chat';
  }
};

export const getInboxClassByType = (type, phoneNumber) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return 'globe-desktop';

    case INBOX_TYPES.FB:
      return 'brand-facebook';

    case INBOX_TYPES.TWITTER:
      return 'brand-twitter';

    case INBOX_TYPES.TWILIO:
      return phoneNumber?.startsWith('whatsapp')
        ? 'brand-whatsapp'
        : 'brand-sms';

    case INBOX_TYPES.WHATSAPP:
      return 'brand-whatsapp';

    case INBOX_TYPES.API:
      return 'cloud';

    case INBOX_TYPES.EMAIL:
      return 'mail';

    case INBOX_TYPES.TELEGRAM:
      return 'brand-telegram';

    case INBOX_TYPES.LINE:
      return 'brand-line';

    case INBOX_TYPES.INSTAGRAM:
      return 'brand-instagram';

    default:
      return 'chat';
  }
};

export const getInboxIconByType = (type, phoneNumber, variant = 'fill') => {
  const iconMap =
    variant === 'fill' ? INBOX_ICON_MAP_FILL : INBOX_ICON_MAP_LINE;
  const defaultIcon =
    variant === 'fill' ? DEFAULT_ICON_FILL : DEFAULT_ICON_LINE;

  // Special case for Twilio (whatsapp and sms)
  if (type === INBOX_TYPES.TWILIO && phoneNumber?.startsWith('whatsapp')) {
    return iconMap[INBOX_TYPES.WHATSAPP];
  }

  return iconMap[type] ?? defaultIcon;
};

export const getInboxWarningIconClass = (type, reauthorizationRequired) => {
  const allowedInboxTypes = [INBOX_TYPES.FB, INBOX_TYPES.EMAIL];
  if (allowedInboxTypes.includes(type) && reauthorizationRequired) {
    return 'warning';
  }
  return '';
};
