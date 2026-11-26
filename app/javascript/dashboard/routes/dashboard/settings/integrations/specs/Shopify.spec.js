import { flushPromises, mount } from '@vue/test-utils';
import Shopify from '../Shopify.vue';

const mocks = vi.hoisted(() => ({
  cloud: false,
  dispatch: vi.fn(),
}));

vi.mock('vue-router', async importOriginal => ({
  ...(await importOriginal()),
  useRoute: () => ({ query: {} }),
  useRouter: () => ({}),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({
    isOnChatwootCloud: { value: mocks.cloud },
    isCloudFeatureEnabled: () => true,
  }),
}));

vi.mock('dashboard/composables/store', async () => {
  const { ref } = await import('vue');
  return {
    useStore: () => ({ dispatch: mocks.dispatch }),
    useMapGetter: () => ref({ isCreatingShopify: false }),
    useFunctionGetter: () =>
      ref({
        id: 'shopify',
        enabled: true,
        hooks: [{ status: true, reference_id: 'store.myshopify.com' }],
      }),
  };
});

describe('Shopify integration settings', () => {
  it.each([
    { cloud: true, storefrontSetup: true },
    { cloud: false, storefrontSetup: false },
  ])(
    'shows storefront setup only on Cloud ($cloud)',
    async ({ cloud, storefrontSetup }) => {
      mocks.cloud = cloud;
      const wrapper = mount(Shopify, {
        global: {
          mocks: { $t: key => key },
          stubs: {
            SettingsLayout: { template: '<div><slot name="body" /></div>' },
            Integration: true,
            Dialog: true,
            Input: true,
            Button: true,
            ShopifyStorefrontWidget: true,
          },
        },
      });
      await flushPromises();

      expect(wrapper.findComponent({ name: 'Integration' }).exists()).toBe(
        true
      );
      expect(
        wrapper.findComponent({ name: 'ShopifyStorefrontWidget' }).exists()
      ).toBe(storefrontSetup);

      wrapper.unmount();
    }
  );
});
