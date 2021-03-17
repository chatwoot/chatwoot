import { INBOX_TYPES } from 'shared/mixins/inboxMixin';

export const getInboxClassByType = (type, phoneNumber) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return 'ion-earth';

    case INBOX_TYPES.FB:
      return 'ion-social-facebook';

    case INBOX_TYPES.TWITTER:
      return 'ion-social-twitter';

    case INBOX_TYPES.TWILIO:
      return phoneNumber.startsWith('whatsapp')
        ? 'ion-social-whatsapp-outline'
        : 'ion-android-textsms';

    case INBOX_TYPES.API:
      return 'ion-cloud';

    case INBOX_TYPES.EMAIL:
      return 'ion-ios-email';

    default:
      return '';
  }
};
