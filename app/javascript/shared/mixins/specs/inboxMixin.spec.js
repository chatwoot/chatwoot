import { shallowMount } from '@vue/test-utils';
import inboxMixin from '../inboxMixin';

describe('inboxMixin', () => {
  it('returns the correct channel type', () => {
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return { inbox: { channel_type: 'Channel::WebWidget' } };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.channelType).toBe('Channel::WebWidget');
  });

  it('isAPIInbox returns true if channel type is API', () => {
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return { inbox: { channel_type: 'Channel::Api' } };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isAPIInbox).toBe(true);
  });

  it('isATwitterInbox returns true if channel type is twitter', () => {
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return { inbox: { channel_type: 'Channel::TwitterProfile' } };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwitterInbox).toBe(true);
  });

  it('isAFacebookInbox returns true if channel type is Facebook', () => {
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return { inbox: { channel_type: 'Channel::FacebookPage' } };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isAFacebookInbox).toBe(true);
  });

  it('isAWebWidgetInbox returns true if channel type is Facebook', () => {
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return { inbox: { channel_type: 'Channel::WebWidget' } };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isAWebWidgetInbox).toBe(true);
  });

  it('isASmsInbox returns true if channel type is sms', () => {
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return { inbox: { channel_type: 'Channel::Sms' } };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isASmsInbox).toBe(true);
  });

  it('isATwilioChannel returns true if channel type is Twilio', () => {
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return {
          inbox: {
            channel_type: 'Channel::TwilioSms',
          },
        };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwilioChannel).toBe(true);
  });

  it('isATwilioSMSChannel returns true if channel type is Twilio and medium is SMS', () => {
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return {
          inbox: {
            channel_type: 'Channel::TwilioSms',
            medium: 'sms',
          },
        };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwilioChannel).toBe(true);
    expect(wrapper.vm.isATwilioSMSChannel).toBe(true);
    expect(wrapper.vm.isASmsInbox).toBe(true);
  });

  it('isATwilioWhatsappChannel returns true if channel type is Twilio and medium is whatsapp', () => {
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return {
          inbox: {
            channel_type: 'Channel::TwilioSms',
            medium: 'whatsapp',
          },
        };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwilioChannel).toBe(true);
    expect(wrapper.vm.isATwilioWhatsappChannel).toBe(true);
  });

  it('isAnEmailChannel returns true if channel type is email', () => {
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return {
          inbox: { channel_type: 'Channel::Email' },
        };
      },
    };
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
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return {
          inbox: {
            channel_type: 'Channel::TwilioSms',
            medium: 'sms',
          },
        };
      },
    };
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
    const Component = {
      render() {},
      mixins: [inboxMixin],
      data() {
        return {
          inbox: {
            channel_type: 'Channel::Telegram',
          },
        };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isATwilioChannel).toBe(false);
    expect(wrapper.vm.isATwitterInbox).toBe(false);
    expect(wrapper.vm.channelType).toBe('Channel::Telegram');
  });
});
