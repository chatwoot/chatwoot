import { shallowMount } from '@vue/test-utils';
import { nextTick, ref } from 'vue';

import ProviderIndex from '../ProviderIndex.vue';
import ShopifyBilling from '../ShopifyBilling.vue';
import StripeBilling from '../Index.vue';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';

const currentAccount = ref({});
const isCloudFeatureEnabled = vi.fn();

vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({
    currentAccount,
    isCloudFeatureEnabled,
  }),
}));

vi.mock('shared/composables/useBranding', () => ({
  useBranding: () => ({
    replaceInstallationName: text => text.replace(/chatwoot/gi, 'Acme'),
  }),
}));

const mountComponent = () =>
  shallowMount(ProviderIndex, {
    global: {
      mocks: {
        $t: key =>
          key === 'BILLING_SETTINGS.SHOPIFY.DESCRIPTION'
            ? 'Your Chatwoot subscription is billed through Shopify.'
            : key,
      },
      stubs: {
        SettingsLayout: {
          name: 'SettingsLayout',
          props: {
            isLoading: Boolean,
            loadingMessage: String,
            noRecordsFound: Boolean,
            noRecordsMessage: String,
          },
          template: '<main><slot name="header" /><slot /></main>',
        },
        BaseSettingsHeader: {
          name: 'BaseSettingsHeader',
          props: ['title', 'description'],
          template: '<header>{{ title }} {{ description }}</header>',
        },
      },
    },
  });

describe('Billing settings provider dispatcher', () => {
  beforeEach(() => {
    currentAccount.value = {};
    isCloudFeatureEnabled.mockReset();
  });

  it('waits for the account before mounting a billing provider', () => {
    const wrapper = mountComponent();

    expect(wrapper.findComponent(StripeBilling).exists()).toBe(false);
    expect(wrapper.findComponent(ShopifyBilling).exists()).toBe(false);
  });

  it('preserves Stripe billing for regular accounts', async () => {
    const wrapper = mountComponent();
    currentAccount.value = {
      id: 1,
      billing_provider: 'stripe',
    };
    await nextTick();

    expect(wrapper.findComponent(StripeBilling).exists()).toBe(true);
    expect(wrapper.findComponent(ShopifyBilling).exists()).toBe(false);
  });

  it('shows Shopify billing when both provider and feature gate match', async () => {
    isCloudFeatureEnabled.mockReturnValue(true);
    const wrapper = mountComponent();
    currentAccount.value = {
      id: 1,
      billing_provider: 'shopify',
    };
    await nextTick();

    expect(wrapper.findComponent(ShopifyBilling).exists()).toBe(true);
    expect(wrapper.findComponent(StripeBilling).exists()).toBe(false);
  });

  it('never falls back to Stripe when Shopify billing is disabled', async () => {
    isCloudFeatureEnabled.mockReturnValue(false);
    const wrapper = mountComponent();
    currentAccount.value = {
      id: 1,
      billing_provider: 'shopify',
    };
    await nextTick();

    expect(wrapper.findComponent(ShopifyBilling).exists()).toBe(false);
    expect(wrapper.findComponent(StripeBilling).exists()).toBe(false);
    expect(wrapper.findComponent(BaseSettingsHeader).props('description')).toBe(
      'Your Acme subscription is billed through Shopify.'
    );
    expect(wrapper.findComponent({ name: 'SettingsLayout' }).props()).toEqual(
      expect.objectContaining({
        noRecordsFound: true,
        noRecordsMessage: 'BILLING_SETTINGS.SHOPIFY.UNAVAILABLE',
      })
    );
  });
});
