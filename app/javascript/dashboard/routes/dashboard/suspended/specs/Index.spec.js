import { shallowMount } from '@vue/test-utils';
import Index from '../Index.vue';

const state = vi.hoisted(() => ({
  isAdmin: true,
  isOnChatwootCloud: true,
  currentAccount: { suspension_category: 'non_payment' },
  hasCategoryMessages: true,
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
    te: () => state.hasCategoryMessages,
  }),
}));

vi.mock('dashboard/composables/useAdmin', () => ({
  useAdmin: () => ({
    isAdmin: {
      get value() {
        return state.isAdmin;
      },
    },
  }),
}));

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: key => ({
    get value() {
      return key === 'getCurrentAccount'
        ? state.currentAccount
        : state.isOnChatwootCloud;
    },
  }),
}));

const mountComponent = () =>
  shallowMount(Index, {
    global: {
      mocks: {
        $t: key => key,
      },
      stubs: {
        EmptyState: {
          name: 'EmptyState',
          props: ['message'],
          template: '<div><slot /></div>',
        },
        RouterLink: {
          template: '<a><slot /></a>',
        },
      },
    },
  });

describe('Suspended account screen', () => {
  beforeEach(() => {
    state.isAdmin = true;
    state.isOnChatwootCloud = true;
    state.currentAccount = { suspension_category: 'non_payment' };
    state.hasCategoryMessages = true;
  });

  it('shows billing guidance to eligible Cloud administrators', () => {
    const wrapper = mountComponent();

    expect(wrapper.findComponent({ name: 'EmptyState' }).props('message')).toBe(
      'APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.NON_PAYMENT'
    );
    expect(wrapper.find('a').exists()).toBe(true);
  });

  it('shows support guidance to agents without billing access', () => {
    state.isAdmin = false;

    const wrapper = mountComponent();

    expect(wrapper.findComponent({ name: 'EmptyState' }).props('message')).toBe(
      'APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.NON_PAYMENT_SUPPORT'
    );
    expect(wrapper.find('a').exists()).toBe(false);
  });

  it('shows support guidance to self-hosted administrators', () => {
    state.isOnChatwootCloud = false;
    state.currentAccount = { suspension_category: null };

    const wrapper = mountComponent();

    expect(wrapper.findComponent({ name: 'EmptyState' }).props('message')).toBe(
      'APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGES.DEFAULT_SUPPORT'
    );
    expect(wrapper.find('a').exists()).toBe(false);
  });

  it('uses the existing localized message when category copy is unavailable', () => {
    state.currentAccount = { suspension_category: 'spam' };
    state.hasCategoryMessages = false;

    const wrapper = mountComponent();

    expect(wrapper.findComponent({ name: 'EmptyState' }).props('message')).toBe(
      'APP_GLOBAL.ACCOUNT_SUSPENDED.MESSAGE'
    );
  });
});
