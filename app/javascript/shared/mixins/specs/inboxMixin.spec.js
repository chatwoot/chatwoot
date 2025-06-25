import { shallowMount } from '@vue/test-utils';
import inboxMixin from '../inboxMixin';

function getComponentConfigForInbox(channelType, additionalConfig = {}) {
  return {
    render() {},
    mixins: [inboxMixin],
    data() {
      return {
        inbox: {
          channel_type: channelType,
          ...additionalConfig,
        },
      };
    },
  };
}

function getComponentConfigForChat(chat) {
  return {
    render() {},
    mixins: [inboxMixin],
    data() {
      return {
        chat,
      };
    },
  };
}

describe('inboxMixin', () => {
  it('returns the correct channel type', () => {
    const Component = getComponentConfigForInbox('Channel::WebWidget');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.channelType).toBe('Channel::WebWidget');
  });

  it('isAPIInbox returns true if channel type is API', () => {
    const Component = getComponentConfigForInbox('Channel::Api');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isAPIInbox).toBe(true);
  });

  it('isATwitterInbox returns true if channel type is twitter', () => {
    const Component = getComponentConfigForInbox('Channel::TwitterProfile');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwitterInbox).toBe(true);
  });

  it('isAFacebookInbox returns true if channel type is Facebook', () => {
    const Component = getComponentConfigForInbox('Channel::FacebookPage');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isAFacebookInbox).toBe(true);
  });

  it('isAWebWidgetInbox returns true if channel type is Facebook', () => {
    const Component = getComponentConfigForInbox('Channel::WebWidget');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isAWebWidgetInbox).toBe(true);
  });

  it('isASmsInbox returns true if channel type is sms', () => {
    const Component = getComponentConfigForInbox('Channel::Sms');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isASmsInbox).toBe(true);
  });

  it('isASmsInbox returns true if channel type is twilio sms', () => {
    const Component = getComponentConfigForInbox('Channel::TwilioSms', {
      medium: 'sms',
    });
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isASmsInbox).toBe(true);
  });

  it('isALineChannel returns true if channel type is Line', () => {
    const Component = getComponentConfigForInbox('Channel::Line');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isALineChannel).toBe(true);
  });

  it('isATelegramChannel returns true if channel type is Telegram', () => {
    const Component = getComponentConfigForInbox('Channel::Telegram');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATelegramChannel).toBe(true);
  });

  it('isATwilioChannel returns true if channel type is Twilio', () => {
    const Component = getComponentConfigForInbox('Channel::TwilioSms');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwilioChannel).toBe(true);
  });

  describe('isATwilioSMSChannel', () => {
    it('returns true if channel type is Twilio and medium is SMS', () => {
      const Component = getComponentConfigForInbox('Channel::TwilioSms', {
        medium: 'sms',
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.isATwilioSMSChannel).toBe(true);
    });

    it('returns false if channel type is Twilio but medium is not SMS', () => {
      const Component = getComponentConfigForInbox('Channel::TwilioSms', {
        medium: 'whatsapp',
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.isATwilioSMSChannel).toBe(false);
    });

    it('returns false if channel type is not Twilio but medium is SMS', () => {
      const Component = getComponentConfigForInbox('Channel::NotTwilio', {
        medium: 'sms',
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.isATwilioSMSChannel).toBe(false);
    });

    it('returns false if neither channel type is Twilio nor medium is SMS', () => {
      const Component = getComponentConfigForInbox('Channel::NotTwilio', {
        medium: 'not_sms',
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.isATwilioSMSChannel).toBe(false);
    });

    it('returns false if channel type is Twilio but medium is empty', () => {
      const Component = getComponentConfigForInbox('Channel::TwilioSms', {
        medium: undefined,
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.isATwilioSMSChannel).toBe(false);
    });
  });

  it('isAnEmailChannel returns true if channel type is email', () => {
    const Component = getComponentConfigForInbox('Channel::Email');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isAnEmailChannel).toBe(true);
  });

  it('isTwitterInboxTweet returns true if Twitter channel type is tweet', () => {
    const Component = getComponentConfigForChat({
      channel_type: 'Channel::TwitterProfile',
      additional_attributes: {
        type: 'tweet',
      },
    });
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isTwitterInboxTweet).toBe(true);
  });

  it('twilioBadge returns string sms if channel type is Twilio and medium is sms', () => {
    const Component = getComponentConfigForInbox('Channel::TwilioSms', {
      medium: 'sms',
    });
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwilioSMSChannel).toBe(true);
    expect(wrapper.vm.twilioBadge).toBe('sms');
  });

  it('twitterBadge returns string twitter-tweet if Twitter channel type is tweet', () => {
    const Component = getComponentConfigForChat({
      id: 1,
      additional_attributes: {
        type: 'tweet',
      },
    });

    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isTwitterInboxTweet).toBe(true);
    expect(wrapper.vm.twitterBadge).toBe('twitter-tweet');
  });

  describe('Badges', () => {
    it('inboxBadge returns string Channel::Telegram if isATwilioChannel and isATwitterInbox is false', () => {
      const Component = getComponentConfigForInbox('Channel::Telegram');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.isATwilioChannel).toBe(false);
      expect(wrapper.vm.isATwitterInbox).toBe(false);
      expect(wrapper.vm.channelType).toBe('Channel::Telegram');
    });

    it('inboxBadge returns correct badge for WhatsApp channel', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxBadge).toBe('whatsapp');
    });

    it('inboxBadge returns the twitterBadge when isATwitterInbox is true', () => {
      const Component = getComponentConfigForInbox('Channel::TwitterProfile');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxBadge).toBe('twitter-dm');
    });

    it('inboxBadge returns the facebookBadge when isAFacebookInbox is true', () => {
      const Component = getComponentConfigForInbox('Channel::FacebookPage');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxBadge).toBe('facebook');
    });

    it('inboxBadge returns the twilioBadge when isATwilioChannel is true', () => {
      const Component = getComponentConfigForInbox('Channel::TwilioSms', {
        medium: 'sms',
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxBadge).toBe('sms');
    });

    it('inboxBadge returns "whatsapp" when isAWhatsAppChannel is true', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxBadge).toBe('whatsapp');
    });

    it('inboxBadge returns the channelType when no specific condition is true', () => {
      const Component = getComponentConfigForInbox('Channel::Email');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxBadge).toBe('Channel::Email');
    });
  });

  describe('#inboxHasFeature', () => {
    it('detects the correct feature', () => {
      const Component = getComponentConfigForInbox('Channel::Telegram');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxHasFeature('replyTo')).toBe(true);
      expect(wrapper.vm.inboxHasFeature('feature-does-not-exist')).toBe(false);
    });

    it('returns false for feature not included', () => {
      const Component = getComponentConfigForInbox('Channel::Sms');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxHasFeature('replyTo')).toBe(false);
      expect(wrapper.vm.inboxHasFeature('feature-does-not-exist')).toBe(false);
    });
  });

  describe('WhatsApp channel', () => {
    it('returns correct whatsAppAPIProvider', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp', {
        provider: 'whatsapp_cloud',
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.whatsAppAPIProvider).toBe('whatsapp_cloud');
    });

    it('returns empty whatsAppAPIProvider if nothing is present', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp', {
        provider: undefined,
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.whatsAppAPIProvider).toBe('');
    });

    it('isAWhatsAppCloudChannel returns true if channel type is WhatsApp and provider is whatsapp_cloud', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp', {
        provider: 'whatsapp_cloud',
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.isAWhatsAppCloudChannel).toBe(true);
    });

    it('is360DialogWhatsAppChannel returns true if channel type is WhatsApp and provider is default', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp', {
        provider: 'default',
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.is360DialogWhatsAppChannel).toBe(true);
    });

    it('isAWhatsAppChannel returns true if channel type is WhatsApp', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.isAWhatsAppChannel).toBe(true);
    });

    it('isAWhatsAppChannel returns true if channel type is Twilio and medium is WhatsApp', () => {
      const Component = getComponentConfigForInbox('Channel::TwilioSms', {
        medium: 'whatsapp',
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.isAWhatsAppChannel).toBe(true);
    });
  });
});
