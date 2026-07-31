import { shallowMount } from '@vue/test-utils';

import Signup from './Index.vue';
import SignupForm from './components/Signup/Form.vue';

vi.mock('vuex', () => ({
  useStore: () => ({
    getters: {
      'globalConfig/get': {
        installationName: 'Chatwoot',
        logo: '/logo.svg',
        logoDark: '/logo-dark.svg',
      },
    },
  }),
}));
vi.mock('shared/composables/useBranding', () => ({
  useBranding: () => ({
    replaceInstallationName: value => value.replace('Chatwoot', 'Acme'),
  }),
}));

const mountComponent = props =>
  shallowMount(Signup, {
    props,
    global: {
      mocks: {
        $t: key =>
          key === 'REGISTER.SHOPIFY.TITLE'
            ? 'Set up Chatwoot for your Shopify store'
            : key,
      },
      stubs: {
        RouterLink: {
          template: '<a><slot /></a>',
        },
      },
    },
  });

describe('Shopify signup', () => {
  it('passes the pending install token to the signup form', () => {
    const wrapper = mountComponent({
      shopifyPendingInstall: 'pending-install-token',
    });

    expect(
      wrapper.findComponent(SignupForm).props('shopifyPendingInstall')
    ).toBe('pending-install-token');
    expect(wrapper.text()).toContain('Set up Acme for your Shopify store');
    expect(wrapper.find('a').exists()).toBe(false);
  });

  it('preserves the regular signup experience without a token', () => {
    const wrapper = mountComponent({});

    expect(
      wrapper.findComponent(SignupForm).props('shopifyPendingInstall')
    ).toBe('');
    expect(wrapper.text()).toContain('REGISTER.GET_STARTED');
    expect(wrapper.find('a').exists()).toBe(true);
  });
});
