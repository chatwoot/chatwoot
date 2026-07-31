import { flushPromises, shallowMount } from '@vue/test-utils';
import Shopify from '../Shopify.vue';
import shopifyAPI from 'dashboard/api/integrations/shopify';

const mocks = vi.hoisted(() => ({
  alert: vi.fn(),
  route: {
    query: {
      shopify_pending_install: 'pending-token',
      source: 'shopify',
    },
  },
  router: {
    replace: vi.fn(),
  },
  store: {
    dispatch: vi.fn(),
  },
}));

vi.mock('vue-router', async importOriginal => ({
  ...(await importOriginal()),
  useRoute: () => mocks.route,
  useRouter: () => mocks.router,
}));

vi.mock('dashboard/composables/store', () => ({
  useFunctionGetter: () => ({
    value: {
      enabled: false,
      hooks: [],
      id: 'shopify',
      logo: '',
      name: 'Shopify',
      description: '',
    },
  }),
  useMapGetter: () => ({ value: { isCreatingShopify: false } }),
  useStore: () => mocks.store,
}));

vi.mock('shared/composables/useMessageFormatter', () => ({
  useMessageFormatter: () => ({ formatMessage: value => value }),
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: mocks.alert,
}));

vi.mock('dashboard/api/integrations/shopify', () => ({
  default: {
    completeInstall: vi.fn(),
  },
}));

describe('Shopify integration pending install', () => {
  beforeEach(() => {
    mocks.alert.mockReset();
    mocks.router.replace.mockReset();
    mocks.store.dispatch.mockReset().mockResolvedValue();
    shopifyAPI.completeInstall.mockReset().mockResolvedValue();
    window.history.pushState(
      {},
      '',
      '/app/accounts/1/settings/integrations/shopify?shopify_pending_install=pending-token&source=shopify'
    );
  });

  it('falls back to browser history when route cleanup fails after a successful install', async () => {
    mocks.router.replace.mockRejectedValue(new Error('route cleanup failed'));
    const replaceState = vi.spyOn(window.history, 'replaceState');

    shallowMount(Shopify);
    await flushPromises();

    expect(shopifyAPI.completeInstall).toHaveBeenCalledWith('pending-token');
    expect(mocks.router.replace).toHaveBeenCalledWith({
      query: { source: 'shopify' },
    });
    expect(replaceState).toHaveBeenCalledWith(
      {},
      document.title,
      expect.not.stringContaining('shopify_pending_install')
    );
    expect(mocks.alert).toHaveBeenCalledWith(
      'INTEGRATION_SETTINGS.SHOPIFY.PENDING_INSTALL.SUCCESS'
    );
    expect(mocks.alert).not.toHaveBeenCalledWith(
      'INTEGRATION_SETTINGS.SHOPIFY.PENDING_INSTALL.ERROR'
    );
  });
});
