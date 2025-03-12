import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import SidemenuIcon from '../SidemenuIcon.vue';

const store = createStore({
  modules: {
    auth: {
      namespaced: false,
      getters: {
        getCurrentAccountId: () => 1,
      },
    },
    accounts: {
      namespaced: true,
      getters: {
        isFeatureEnabledonAccount: () => () => false,
      },
    },
  },
});

describe('SidemenuIcon', () => {
  test('matches snapshot', () => {
    const wrapper = shallowMount(SidemenuIcon, {
      stubs: { WootButton: { template: '<button><slot /></button>' } },
      global: { plugins: [store] },
    });
    expect(wrapper.vm).toBeTruthy();
    expect(wrapper.element).toMatchSnapshot();
  });
});
