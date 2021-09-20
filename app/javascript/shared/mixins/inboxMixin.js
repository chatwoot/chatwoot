export const INBOX_TYPES = {
  WEB: 'Channel::WebWidget',
  FB: 'Channel::FacebookPage',
  TWITTER: 'Channel::TwitterProfile',
  TWILIO: 'Channel::TwilioSms',
  API: 'Channel::Api',
  EMAIL: 'Channel::Email',
  TELEGRAM: 'Channel::Telegram',
  LINE: 'Channel::Line',
};

export default {
  computed: {
    channelType() {
      return this.inbox.channel_type;
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
    isATwilioSMSChannel() {
      const { medium: medium = '' } = this.inbox;
      return this.isATwilioChannel && medium === 'sms';
    },
    isATwilioWhatsappChannel() {
      const { medium: medium = '' } = this.inbox;
      return this.isATwilioChannel && medium === 'whatsapp';
    },
    findInboxBadgeType() {
      if (this.isATwilioChannel) {
        return `${this.isATwilioSMSChannel ? 'sms' : 'whatsapp'}`;
      }
      if (this.isATwitterInbox) {
        return `${
          this.chat.additional_attributes.type === 'tweet'
            ? 'twitter-tweet'
            : 'twitter-chat'
        }`;
      }
      return this.chat.meta.channel;
    },
  },
};
