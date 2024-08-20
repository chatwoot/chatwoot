import { shallowMount, createLocalVue } from '@vue/test-utils';
import { useCampaign } from '../useCampaign';
import { defineComponent } from 'vue';

const buildComponent = routeName => {
  return defineComponent({
    setup() {
      return useCampaign();
    },
    computed: {
      $route() {
        return { name: routeName };
      },
    },
    template: '<div></div>',
  });
};

describe('useCampaign', () => {
  let localVue;

  beforeEach(() => {
    localVue = createLocalVue();
    global.window = Object.create(window);
  });

  it('returns the correct campaign type', () => {
    const Component = buildComponent('one_off');
    const wrapper = shallowMount(Component, { localVue });
    expect(wrapper.vm.campaignType).toBe('one_off');
  });

  it('isOneOffType returns true if path is one_off', () => {
    const Component = buildComponent('one_off');
    const wrapper = shallowMount(Component, { localVue });
    expect(wrapper.vm.isOneOffType).toBe(true);
  });

  it('isOngoingType returns true if path is ongoing_campaigns', () => {
    const Component = buildComponent('ongoing_campaigns');
    const wrapper = shallowMount(Component, { localVue });
    expect(wrapper.vm.isOngoingType).toBe(true);
  });
});
