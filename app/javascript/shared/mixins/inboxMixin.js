import { INBOX_TYPES } from 'dashboard/helper/inbox';

export const INBOX_FEATURES = {
  REPLY_TO: 'replyTo',
  REPLY_TO_OUTGOING: 'replyToOutgoing',
};

// This is a single source of truth for inbox features
// This is used to check if a feature is available for a particular inbox or not
export const INBOX_FEATURE_MAP = {
  [INBOX_FEATURES.REPLY_TO]: [
    INBOX_TYPES.FB,
    INBOX_TYPES.WEB,
    INBOX_TYPES.TWITTER,
    INBOX_TYPES.WHATSAPP,
    INBOX_TYPES.TELEGRAM,
    INBOX_TYPES.TIKTOK,
    INBOX_TYPES.API,
  ],
  [INBOX_FEATURES.REPLY_TO_OUTGOING]: [
    INBOX_TYPES.WEB,
    INBOX_TYPES.TWITTER,
    INBOX_TYPES.WHATSAPP,
    INBOX_TYPES.TELEGRAM,
    INBOX_TYPES.TIKTOK,
    INBOX_TYPES.API,
  ],
};

export default {
  computed: {
    channelType() {
      return this.inbox.channel_type;
    },
    whatsAppAPIProvider() {
      return this.inbox.provider || '';
    },
    isAMicrosoftInbox() {
      return this.isAnEmailChannel && this.inbox.provider === 'microsoft';
    },
    isAGoogleInbox() {
      return this.isAnEmailChannel && this.inbox.provider === 'google';
    },
    isAPIInbox() {
      return this.channelType === INBOX_TYPES.API;
    },
    isAFacebookInbox() {
      return this.channelType === INBOX_TYPES.FB;
    },
    isAWebWidgetInbox() {
      return this.channelType === INBOX_TYPES.WEB;
    },
    isAnEmailChannel() {
      return this.channelType === INBOX_TYPES.EMAIL;
    },
    isATelegramChannel() {
      return this.channelType === INBOX_TYPES.TELEGRAM;
    },
    isAWhatsAppCloudChannel() {
      return (
        this.channelType === INBOX_TYPES.WHATSAPP &&
        this.whatsAppAPIProvider === 'whatsapp_cloud'
      );
    },
    is360DialogWhatsAppChannel() {
      return (
        this.channelType === INBOX_TYPES.WHATSAPP &&
        this.whatsAppAPIProvider === 'default'
      );
    },
    chatAdditionalAttributes() {
      const { additional_attributes: additionalAttributes } = this.chat || {};
      return additionalAttributes || {};
    },
    facebookBadge() {
      return this.chatAdditionalAttributes.type || 'facebook';
    },
    inboxBadge() {
      let badgeKey = '';
      if (this.isAFacebookInbox) {
        badgeKey = this.facebookBadge;
      } else if (this.isAWhatsAppChannel) {
        badgeKey = 'whatsapp';
      } else if (this.isATiktokChannel) {
        badgeKey = 'tiktok';
      }
      return badgeKey || this.channelType;
    },
    isAWhatsAppChannel() {
      return this.channelType === INBOX_TYPES.WHATSAPP;
    },
    isAnInstagramChannel() {
      return this.channelType === INBOX_TYPES.INSTAGRAM;
    },
    isATiktokChannel() {
      return this.channelType === INBOX_TYPES.TIKTOK;
    },
    isABaileysWhatsAppChannel() {
      return this.channelType === INBOX_TYPES.BAILEYS_WHATSAPP;
    },
  },
  methods: {
    inboxHasFeature(feature) {
      return INBOX_FEATURE_MAP[feature]?.includes(this.channelType) ?? false;
    },
  },
};
