import { INBOX_TYPES } from 'shared/mixins/inboxMixin';

export const getInboxClassByType = (type, phoneNumber) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return 'globe';

    case INBOX_TYPES.FB:
      return 'facebook';

    case INBOX_TYPES.TWITTER:
      return 'twitter';

    case INBOX_TYPES.TWILIO:
      return phoneNumber.startsWith('whatsapp') ? 'message-circle' : 'send';

    case INBOX_TYPES.API:
      return 'cloud';

    case INBOX_TYPES.EMAIL:
      return 'mail';

    default:
      return '';
  }
};
