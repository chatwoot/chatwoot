import { INBOX_TYPES } from 'shared/mixins/inboxMixin';

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

    default:
      return 'chat';
  }
};

export const getInboxWarningIconClass = (type, reauthorizationRequired) => {
  const allowedInboxTypes = [INBOX_TYPES.FB, INBOX_TYPES.EMAIL];
  if (allowedInboxTypes.includes(type) && reauthorizationRequired) {
    return 'warning';
  }
  return '';
};
