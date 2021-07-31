import { shallowMount } from '@vue/test-utils';
import campaignMixin from '../campaignMixin';
import inboxMixin from '../inboxMixin';

describe('campaignMixin', () => {
  it('returns the correct campaign type', () => {
    const Component = {
      render() {},
      mixins: [campaignMixin, inboxMixin],
      data() {
        return {
          inbox: {
            channel_type: 'Channel::TwilioSms',
            phone_number: '+91944444444',
          },
        };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.campaignType).toBe('one_off');
  });
  it('isOnOffType returns true if campaign type is ongoing', () => {
    const Component = {
      render() {},
      mixins: [campaignMixin, inboxMixin],
      data() {
        return { inbox: { channel_type: 'Channel::WebWidget' } };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isOngoingType).toBe(true);
  });
  it('isOngoingType returns true if campaign type is one_off', () => {
    const Component = {
      render() {},
      mixins: [campaignMixin, inboxMixin],
      data() {
        return {
          inbox: {
            channel_type: 'Channel::TwilioSms',
            phone_number: '+91944444444',
          },
        };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isOnOffType).toBe(true);
  });
});
