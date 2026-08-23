import { INBOX_TYPES, isVoiceCallEnabled } from 'dashboard/helper/inbox';
import {
  CHANNEL_DEFINITIONS,
  INBOX_FEATURES,
} from 'dashboard/constants/channelDefinitions';

// Derived from the single channelDefinitions source of truth; used to check if
// a feature is available for a particular inbox.
export const INBOX_FEATURE_MAP = Object.fromEntries(
  Object.values(INBOX_FEATURES).map(feature => [
    feature,
    CHANNEL_DEFINITIONS.filter(definition =>
      definition.features.includes(feature)
    ).map(definition => definition.type),
  ])
);

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
    isATwitterInbox() {
      return this.channelType === INBOX_TYPES.TWITTER;
    },
    isAFacebookInbox() {
      return this.channelType === INBOX_TYPES.FB;
    },
    isAWebWidgetInbox() {
      return this.channelType === INBOX_TYPES.WEB;
    },
    isATwilioChannel() {
      return this.channelType === INBOX_TYPES.TWILIO;
    },
    isALineChannel() {
      return this.channelType === INBOX_TYPES.LINE;
    },
    voiceCallEnabled() {
      return isVoiceCallEnabled(this.inbox);
    },
    isAnEmailChannel() {
      return this.channelType === INBOX_TYPES.EMAIL;
    },
    isATelegramChannel() {
      return this.channelType === INBOX_TYPES.TELEGRAM;
    },
    isATwilioSMSChannel() {
      const { medium: medium = '' } = this.inbox;
      return this.isATwilioChannel && medium === 'sms';
    },
    isASmsInbox() {
      return this.channelType === INBOX_TYPES.SMS || this.isATwilioSMSChannel;
    },
    isATwilioWhatsAppChannel() {
      const { medium: medium = '' } = this.inbox;
      return this.isATwilioChannel && medium === 'whatsapp';
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
    isAWhatsAppUnofficialChannel() {
      return (
        this.channelType === INBOX_TYPES.WHATSAPP &&
        this.whatsAppAPIProvider === 'whatsapp_unofficial'
      );
    },
    chatAdditionalAttributes() {
      const { additional_attributes: additionalAttributes } = this.chat || {};
      return additionalAttributes || {};
    },
    isTwitterInboxTweet() {
      return this.chatAdditionalAttributes.type === 'tweet';
    },
    twilioBadge() {
      return `${this.isATwilioSMSChannel ? 'sms' : 'whatsapp'}`;
    },
    twitterBadge() {
      return `${this.isTwitterInboxTweet ? 'twitter-tweet' : 'twitter-dm'}`;
    },
    facebookBadge() {
      return this.chatAdditionalAttributes.type || 'facebook';
    },
    inboxBadge() {
      let badgeKey = '';
      if (this.isATwitterInbox) {
        badgeKey = this.twitterBadge;
      } else if (this.isAFacebookInbox) {
        badgeKey = this.facebookBadge;
      } else if (this.isATwilioChannel) {
        badgeKey = this.twilioBadge;
      } else if (this.isAWhatsAppChannel) {
        badgeKey = 'whatsapp';
      } else if (this.isATiktokChannel) {
        badgeKey = 'tiktok';
      }
      return badgeKey || this.channelType;
    },
    isAWhatsAppChannel() {
      return (
        this.channelType === INBOX_TYPES.WHATSAPP ||
        this.isATwilioWhatsAppChannel
      );
    },
    isAnInstagramChannel() {
      return this.channelType === INBOX_TYPES.INSTAGRAM;
    },
    isATiktokChannel() {
      return this.channelType === INBOX_TYPES.TIKTOK;
    },
  },
  methods: {
    inboxHasFeature(feature) {
      return INBOX_FEATURE_MAP[feature]?.includes(this.channelType) ?? false;
    },
  },
};
