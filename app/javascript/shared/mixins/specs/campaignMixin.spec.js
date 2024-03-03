import { shallowMount } from '@vue/test-utils';
import campaignMixin from '../campaignMixin';

const buildComponent = routeName => ({
  template: '<div></div>',
  computed: {
    $route() {
      return { name: routeName };
    },
  },
  mixins: [campaignMixin],
});

describe('campaignMixin', () => {
  beforeEach(() => {
    global.window = Object.create(window);
  });
  it('returns the correct campaign type', () => {
    const Component = buildComponent('one_off');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.campaignType).toBe('one_off');
  });
  it('isOneOffType returns true if path is one_off', () => {
    const Component = buildComponent('one_off');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isOneOffType).toBe(true);
  });

  it('isOngoingType returns true if path is ongoing_campaigns', () => {
    const Component = buildComponent('ongoing_campaigns');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isOngoingType).toBe(true);
  });
});
