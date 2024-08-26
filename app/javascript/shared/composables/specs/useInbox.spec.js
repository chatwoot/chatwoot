import { describe, it, expect, vi } from 'vitest';
import { useInbox } from '../useInbox';

// Mock the useStore composable
vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({
    getters: {
      'inboxes/getInbox': vi.fn(id => ({
        id,
        channel_type: 'Channel::WebWidget',
      })),
      getSelectedChat: {
        id: 1,
        inbox_id: 1,
        channel_type: 'Channel::WebWidget',
      },
    },
  }),
}));

describe('useInbox', () => {
  const createInbox = (channelType, additionalConfig = {}) => ({
    channel_type: channelType,
    ...additionalConfig,
  });

  it('returns the correct channel type', () => {
    const inbox = createInbox('Channel::WebWidget');
    const { channelType } = useInbox({ inboxObj: inbox });
    expect(channelType.value).toBe('Channel::WebWidget');
  });

  it('isAPIInbox returns true if channel type is API', () => {
    const inbox = createInbox('Channel::Api');
    const { isAPIInbox } = useInbox({ inboxObj: inbox });
    expect(isAPIInbox.value).toBe(true);
  });

  it('isATwitterInbox returns true if channel type is twitter', () => {
    const inbox = createInbox('Channel::TwitterProfile');
    const { isATwitterInbox } = useInbox({ inboxObj: inbox });
    expect(isATwitterInbox.value).toBe(true);
  });

  it('isAFacebookInbox returns true if channel type is Facebook', () => {
    const inbox = createInbox('Channel::FacebookPage');
    const { isAFacebookInbox } = useInbox({ inboxObj: inbox });
    expect(isAFacebookInbox.value).toBe(true);
  });

  it('isAWebWidgetInbox returns true if channel type is WebWidget', () => {
    const inbox = createInbox('Channel::WebWidget');
    const { isAWebWidgetInbox } = useInbox({ inboxObj: inbox });
    expect(isAWebWidgetInbox.value).toBe(true);
  });

  it('isASmsInbox returns true if channel type is sms', () => {
    const inbox = createInbox('Channel::Sms');
    const { isASmsInbox } = useInbox({ inboxObj: inbox });
    expect(isASmsInbox.value).toBe(true);
  });

  it('isASmsInbox returns true if channel type is twilio sms', () => {
    const inbox = createInbox('Channel::TwilioSms', { medium: 'sms' });
    const { isASmsInbox } = useInbox({ inboxObj: inbox });
    expect(isASmsInbox.value).toBe(true);
  });

  describe('isATwilioSMSChannel', () => {
    it('returns true if channel type is Twilio and medium is SMS', () => {
      const inbox = createInbox('Channel::TwilioSms', { medium: 'sms' });
      const { isATwilioSMSChannel } = useInbox({ inboxObj: inbox });
      expect(isATwilioSMSChannel.value).toBe(true);
    });

    it('returns false if channel type is Twilio but medium is not SMS', () => {
      const inbox = createInbox('Channel::TwilioSms', { medium: 'whatsapp' });
      const { isATwilioSMSChannel } = useInbox({ inboxObj: inbox });
      expect(isATwilioSMSChannel.value).toBe(false);
    });

    it('returns false if channel type is not Twilio but medium is SMS', () => {
      const inbox = createInbox('Channel::NotTwilio', { medium: 'sms' });
      const { isATwilioSMSChannel } = useInbox({ inboxObj: inbox });
      expect(isATwilioSMSChannel.value).toBe(false);
    });
  });

  describe('Badges', () => {
    it('inboxBadge returns correct badge for Telegram', () => {
      const inbox = createInbox('Channel::Telegram');
      const { inboxBadge } = useInbox({ inboxObj: inbox });
      expect(inboxBadge.value).toBe('Channel::Telegram');
    });

    it('inboxBadge returns correct badge for WhatsApp channel', () => {
      const inbox = createInbox('Channel::Whatsapp');
      const { inboxBadge } = useInbox({ inboxObj: inbox });
      expect(inboxBadge.value).toBe('whatsapp');
    });

    it('inboxBadge returns the twitterBadge when isATwitterInbox is true', () => {
      const inbox = createInbox('Channel::TwitterProfile');
      const { inboxBadge } = useInbox({ inboxObj: inbox });
      expect(inboxBadge.value).toBe('twitter-dm');
    });
  });

  describe('WhatsApp channel', () => {
    it('returns correct whatsAppAPIProvider', () => {
      const inbox = createInbox('Channel::Whatsapp', {
        provider: 'whatsapp_cloud',
      });
      const { whatsAppAPIProvider } = useInbox({ inboxObj: inbox });
      expect(whatsAppAPIProvider.value).toBe('whatsapp_cloud');
    });

    it('isAWhatsAppCloudChannel returns true if channel type is WhatsApp and provider is whatsapp_cloud', () => {
      const inbox = createInbox('Channel::Whatsapp', {
        provider: 'whatsapp_cloud',
      });
      const { isAWhatsAppCloudChannel } = useInbox({ inboxObj: inbox });
      expect(isAWhatsAppCloudChannel.value).toBe(true);
    });

    it('is360DialogWhatsAppChannel returns true if channel type is WhatsApp and provider is default', () => {
      const inbox = createInbox('Channel::Whatsapp', { provider: 'default' });
      const { is360DialogWhatsAppChannel } = useInbox({ inboxObj: inbox });
      expect(is360DialogWhatsAppChannel.value).toBe(true);
    });
  });

  describe('#inboxHasFeature', () => {
    it('detects the correct feature', () => {
      const inbox = createInbox('Channel::Telegram');
      const { inboxHasFeature } = useInbox({ inboxObj: inbox });
      expect(inboxHasFeature('replyTo')).toBe(true);
      expect(inboxHasFeature('feature-does-not-exist')).toBe(false);
    });

    it('returns false for feature not included', () => {
      const inbox = createInbox('Channel::Sms');
      const { inboxHasFeature } = useInbox({ inboxObj: inbox });
      expect(inboxHasFeature('replyTo')).toBe(false);
      expect(inboxHasFeature('feature-does-not-exist')).toBe(false);
    });
  });
});
