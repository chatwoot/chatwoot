import {
  getChannelType,
  getWhatsAppAPIProvider,
  isAnEmailChannel,
  isAMicrosoftInbox,
  isAGoogleInbox,
  isAPIInbox,
  isATwitterInbox,
  isAFacebookInbox,
  isAWebWidgetInbox,
  isATwilioChannel,
  isALineChannel,
  isATelegramChannel,
  isATwilioSMSChannel,
  isASmsInbox,
  isAWhatsAppCloudChannel,
  is360DialogWhatsAppChannel,
  isAWhatsAppChannel,
  isTwitterInboxTweet,
  getInboxBadge,
  inboxHasFeature,
} from '../inboxHelper';

import { INBOX_TYPES } from '../../constants/inbox';

describe('inboxHelper', () => {
  describe('getChannelType', () => {
    it('returns the correct channel type', () => {
      const inbox = { channel_type: INBOX_TYPES.WEB };
      expect(getChannelType(inbox)).toBe(INBOX_TYPES.WEB);
    });
  });

  describe('getWhatsAppAPIProvider', () => {
    it('returns the correct provider', () => {
      const inbox = { provider: 'whatsapp_cloud' };
      expect(getWhatsAppAPIProvider(inbox)).toBe('whatsapp_cloud');
    });

    it('returns empty string if provider is not present', () => {
      const inbox = {};
      expect(getWhatsAppAPIProvider(inbox)).toBe('');
    });
  });

  describe('channel type checks', () => {
    it('isAnEmailChannel returns true for email channel', () => {
      const inbox = { channel_type: INBOX_TYPES.EMAIL };
      expect(isAnEmailChannel(inbox)).toBe(true);
    });

    it('isAMicrosoftInbox returns true for Microsoft email inbox', () => {
      const inbox = { channel_type: INBOX_TYPES.EMAIL, provider: 'microsoft' };
      expect(isAMicrosoftInbox(inbox)).toBe(true);
    });

    it('isAGoogleInbox returns true for Google email inbox', () => {
      const inbox = { channel_type: INBOX_TYPES.EMAIL, provider: 'google' };
      expect(isAGoogleInbox(inbox)).toBe(true);
    });

    it('isAPIInbox returns true for API inbox', () => {
      const inbox = { channel_type: INBOX_TYPES.API };
      expect(isAPIInbox(inbox)).toBe(true);
    });

    it('isATwitterInbox returns true for Twitter inbox', () => {
      const inbox = { channel_type: INBOX_TYPES.TWITTER };
      expect(isATwitterInbox(inbox)).toBe(true);
    });

    it('isAFacebookInbox returns true for Facebook inbox', () => {
      const inbox = { channel_type: INBOX_TYPES.FB };
      expect(isAFacebookInbox(inbox)).toBe(true);
    });

    it('isAWebWidgetInbox returns true for WebWidget inbox', () => {
      const inbox = { channel_type: INBOX_TYPES.WEB };
      expect(isAWebWidgetInbox(inbox)).toBe(true);
    });

    it('isATwilioChannel returns true for Twilio channel', () => {
      const inbox = { channel_type: INBOX_TYPES.TWILIO };
      expect(isATwilioChannel(inbox)).toBe(true);
    });

    it('isALineChannel returns true for Line channel', () => {
      const inbox = { channel_type: INBOX_TYPES.LINE };
      expect(isALineChannel(inbox)).toBe(true);
    });

    it('isATelegramChannel returns true for Telegram channel', () => {
      const inbox = { channel_type: INBOX_TYPES.TELEGRAM };
      expect(isATelegramChannel(inbox)).toBe(true);
    });

    it('isASmsInbox returns true for SMS channel', () => {
      const inbox = { channel_type: INBOX_TYPES.SMS };
      expect(isASmsInbox(inbox)).toBe(true);
    });

    it('isAWhatsAppCloudChannel returns true for WhatsApp Cloud channel', () => {
      const inbox = {
        channel_type: INBOX_TYPES.WHATSAPP,
        provider: 'whatsapp_cloud',
      };
      expect(isAWhatsAppCloudChannel(inbox)).toBe(true);
    });

    it('is360DialogWhatsAppChannel returns true for 360Dialog WhatsApp channel', () => {
      const inbox = {
        channel_type: INBOX_TYPES.WHATSAPP,
        provider: '360dialog',
      };
      expect(is360DialogWhatsAppChannel(inbox)).toBe(true);
    });

    it('isAWhatsAppChannel returns true for WhatsApp channel', () => {
      const inbox = { channel_type: INBOX_TYPES.WHATSAPP };
      expect(isAWhatsAppChannel(inbox)).toBe(true);
    });

    it('isATwilioSMSChannel returns true for Twilio SMS channel', () => {
      const inbox = { channel_type: INBOX_TYPES.TWILIO, medium: 'sms' };
      expect(isATwilioSMSChannel(inbox)).toBe(true);
    });
  });

  describe('isTwitterInboxTweet', () => {
    it('returns true if chat type is tweet', () => {
      const chat = { additional_attributes: { type: 'tweet' } };
      expect(isTwitterInboxTweet(chat)).toBe(true);
    });

    it('returns false if chat type is not tweet', () => {
      const chat = { additional_attributes: { type: 'dm' } };
      expect(isTwitterInboxTweet(chat)).toBe(false);
    });
  });

  describe('getInboxBadge', () => {
    it('returns correct badge for Twitter inbox', () => {
      const inbox = { channel_type: INBOX_TYPES.TWITTER };
      expect(getInboxBadge(inbox)).toBe('twitter');
    });

    it('returns correct badge for Facebook inbox', () => {
      const inbox = { channel_type: INBOX_TYPES.FB };
      expect(getInboxBadge(inbox)).toBe('facebook');
    });

    it('returns correct badge for Twilio SMS channel', () => {
      const inbox = { channel_type: INBOX_TYPES.TWILIO, medium: 'sms' };
      expect(getInboxBadge(inbox)).toBe('sms');
    });

    it('returns correct badge for WhatsApp channel', () => {
      const inbox = { channel_type: INBOX_TYPES.WHATSAPP };
      expect(getInboxBadge(inbox)).toBe('whatsapp');
    });

    it('returns channel type for other inboxes', () => {
      const inbox = { channel_type: INBOX_TYPES.API };
      expect(getInboxBadge(inbox)).toBe(INBOX_TYPES.API);
    });
  });

  describe('inboxHasFeature', () => {
    it('returns true for supported features', () => {
      const inbox = { channel_type: INBOX_TYPES.WEB };
      expect(inboxHasFeature(inbox, 'replyTo')).toBe(true);
    });

    it('returns false for unsupported features', () => {
      const inbox = { channel_type: INBOX_TYPES.SMS };
      expect(inboxHasFeature(inbox, 'replyTo')).toBe(false);
    });

    it('returns false for non-existent features', () => {
      const inbox = { channel_type: INBOX_TYPES.WEB };
      expect(inboxHasFeature(inbox, 'nonExistentFeature')).toBe(false);
    });
  });
});
