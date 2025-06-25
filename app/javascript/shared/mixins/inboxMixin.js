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
};

export default {
  computed: {
    channelType() {
      return this.inbox.channel_type;
    },
    whatsAppAPIProvider() {
      return this.inbox.provider || '';
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
      }
      return badgeKey || this.channelType;
    },
    isAWhatsAppChannel() {
      return (
        this.channelType === INBOX_TYPES.WHATSAPP ||
        this.isATwilioWhatsAppChannel
      );
    },
  },
};
