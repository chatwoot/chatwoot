import { INBOX_TYPES } from 'shared/mixins/inboxMixin';

export const getInboxClassByType = (type, phoneNumber) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return 'globe-desktop';

    case INBOX_TYPES.FB:
      return 'brand-facebook';

    case INBOX_TYPES.TWITTER:
      return 'brand-twitter';

    case INBOX_TYPES.TWILIO:
      return phoneNumber.startsWith('whatsapp')
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

export const getStandardCustomFields = () => {
  return {
    pre_chat_message: 'Share your queries or comments here.',
    pre_chat_fields: [
      {
        label: 'Email Id',
        name: 'emailAddress',
        type: 'email',
        field_type: 'standard',
        required: false,
        enabled: false,
      },
      {
        label: 'Full name',
        name: 'fullName',
        type: 'text',
        field_type: 'standard',
        required: false,
        enabled: false,
      },
      {
        label: 'Phone number',
        name: 'phoneNumber',
        type: 'text',
        field_type: 'standard',
        required: false,
        enabled: false,
      },
    ],
  };
};
