import { shallowMount } from '@vue/test-utils';
import inboxMixin from '../inboxMixin';

function getComponentConfig(channelType, additionalConfig = {}) {
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

describe('inboxMixin', () => {
  it('returns the correct channel type', () => {
    const Component = getComponentConfig('Channel::WebWidget');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.channelType).toBe('Channel::WebWidget');
  });

  it('isAPIInbox returns true if channel type is API', () => {
    const Component = getComponentConfig('Channel::Api');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isAPIInbox).toBe(true);
  });

  it('isATwitterInbox returns true if channel type is twitter', () => {
    const Component = getComponentConfig('Channel::TwitterProfile');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwitterInbox).toBe(true);
  });

  it('isAFacebookInbox returns true if channel type is Facebook', () => {
    const Component = getComponentConfig('Channel::FacebookPage');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isAFacebookInbox).toBe(true);
  });

  it('isAWebWidgetInbox returns true if channel type is Facebook', () => {
    const Component = getComponentConfig('Channel::WebWidget');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isAWebWidgetInbox).toBe(true);
  });

  it('isASmsInbox returns true if channel type is sms', () => {
    const Component = getComponentConfig('Channel::Sms');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isASmsInbox).toBe(true);
  });

  it('isALineChannel returns true if channel type is Line', () => {
    const Component = getComponentConfig('Channel::Line');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isALineChannel).toBe(true);
  });

  it('isATelegramChannel returns true if channel type is Telegram', () => {
    const Component = getComponentConfig('Channel::Telegram');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATelegramChannel).toBe(true);
  });

  it('isATwilioChannel returns true if channel type is Twilio', () => {
    const Component = getComponentConfig('Channel::TwilioSms');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwilioChannel).toBe(true);
  });

  it('isATwilioSMSChannel returns true if channel type is Twilio and medium is SMS', () => {
    const Component = getComponentConfig('Channel::TwilioSms', {
      medium: 'sms',
    });
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwilioChannel).toBe(true);
    expect(wrapper.vm.isATwilioSMSChannel).toBe(true);
    expect(wrapper.vm.isASmsInbox).toBe(true);
  });

  it('isATwilioWhatsAppChannel returns true if channel type is Twilio and medium is WhatsApp', () => {
    const Component = getComponentConfig('Channel::TwilioSms', {
      medium: 'whatsapp',
    });
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwilioChannel).toBe(true);
    expect(wrapper.vm.isATwilioWhatsAppChannel).toBe(true);
  });

  it('isAnEmailChannel returns true if channel type is email', () => {
    const Component = getComponentConfig('Channel::Email');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isAnEmailChannel).toBe(true);
  });

  it('isTwitterInboxTweet returns true if Twitter channel type is tweet', () => {
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return {
          chat: {
            channel_type: 'Channel::TwitterProfile',
            additional_attributes: {
              type: 'tweet',
            },
          },
        };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isTwitterInboxTweet).toBe(true);
  });

  it('twilioBadge returns string sms if channel type is Twilio and medium is sms', () => {
    const Component = getComponentConfig('Channel::TwilioSms', {
      medium: 'sms',
    });
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwilioSMSChannel).toBe(true);
    expect(wrapper.vm.twilioBadge).toBe('sms');
  });

  it('twitterBadge returns string twitter-tweet if Twitter channel type is tweet', () => {
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return {
          chat: {
            id: 1,
            additional_attributes: {
              type: 'tweet',
            },
          },
        };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isTwitterInboxTweet).toBe(true);
    expect(wrapper.vm.twitterBadge).toBe('twitter-tweet');
  });

  it('inboxBadge returns string Channel::Telegram if isATwilioChannel and isATwitterInbox is false', () => {
    const Component = getComponentConfig('Channel::Telegram');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwilioChannel).toBe(false);
    expect(wrapper.vm.isATwitterInbox).toBe(false);
    expect(wrapper.vm.channelType).toBe('Channel::Telegram');
  });

  it('returns correct whatsAppAPIProvider', () => {});

  describe('#inboxHasFeature', () => {
    it('detects the correct feature', () => {
      const Component = getComponentConfig('Channel::Telegram');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxHasFeature('replyTo')).toBe(true);
      expect(wrapper.vm.inboxHasFeature('feature-does-not-exist')).toBe(false);
    });

    it('returns false for feature not included', () => {
      const Component = getComponentConfig('Channel::Sms');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxHasFeature('replyTo')).toBe(false);
      expect(wrapper.vm.inboxHasFeature('feature-does-not-exist')).toBe(false);
    });
  });
});
