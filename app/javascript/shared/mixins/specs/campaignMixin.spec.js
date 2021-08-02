import { shallowMount } from '@vue/test-utils';
import campaignMixin from '../campaignMixin';

describe('campaignMixin', () => {
  beforeEach(() => {
    global.window = Object.create(window);
  });
  it('returns the correct campaign type', () => {
    const url = 'http://localhost:3000/app/accounts/1/campaigns/one_off';
    Object.defineProperty(window, 'location', {
      value: {
        href: url,
      },
    });
    window.location.href = url;
    const Component = {
      render() {},
      mixins: [campaignMixin],
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.campaignType).toBe('one_off');
  });
  it('isOnOffType returns true if campaign type is one_off', () => {
    const url = 'http://localhost:3000/app/accounts/1/campaigns/one_off';
    Object.defineProperty(window, 'location', {
      value: {
        href: url,
      },
    });
    const Component = {
      render() {},
      mixins: [campaignMixin],
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isOnOffType).toBe(true);
  });

});
