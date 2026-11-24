import { flushPromises, mount } from '@vue/test-utils';
import shopifyAPI from 'dashboard/api/integrations/shopify';
import ShopifyStorefrontWidget from '../ShopifyStorefrontWidget.vue';

const mocks = vi.hoisted(() => ({
  dispatch: vi.fn(),
  inboxes: [{ id: 21, name: 'Store support' }],
  alert: vi.fn(),
}));

vi.mock('dashboard/composables/store', async () => {
  const { ref } = await import('vue');
  return {
    useStore: () => ({ dispatch: mocks.dispatch }),
    useMapGetter: () => ref(mocks.inboxes),
  };
});

vi.mock('dashboard/composables', () => ({
  useAlert: mocks.alert,
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/api/integrations/shopify', () => ({
  default: {
    getStorefrontWidget: vi.fn(),
    saveStorefrontWidget: vi.fn(),
    connect: vi.fn(),
  },
}));

const mountComponent = () =>
  mount(ShopifyStorefrontWidget, {
    props: { storeDomain: 'shop.myshopify.com' },
    global: {
      stubs: {
        Button: {
          props: ['disabled', 'label'],
          template: '<button :disabled="disabled">{{ label }}</button>',
        },
        WootLoadingState: true,
        RouterLink: true,
      },
    },
  });

describe('Shopify storefront widget setup', () => {
  const themeEditorUrl =
    'https://shop.myshopify.com/admin/themes/current/editor';

  beforeEach(() => {
    mocks.dispatch.mockResolvedValue(true);
    shopifyAPI.getStorefrontWidget.mockResolvedValue({
      data: { inbox_id: null, theme_editor_url: null },
    });
  });

  it('opens the theme editor after saving the selected Website inbox', async () => {
    shopifyAPI.saveStorefrontWidget.mockResolvedValue({
      data: { inbox_id: 21, theme_editor_url: themeEditorUrl },
    });
    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.find('a').exists()).toBe(false);
    await wrapper.get('select').setValue('21');
    await wrapper.get('form').trigger('submit');
    await flushPromises();

    expect(shopifyAPI.saveStorefrontWidget).toHaveBeenCalledWith(21);
    expect(wrapper.get('a').attributes('href')).toBe(themeEditorUrl);
  });

  it('offers to reconnect the existing store when Shopify rejects the token', async () => {
    shopifyAPI.getStorefrontWidget.mockRejectedValue({
      response: { data: { code: 'shopify_reauthorization_required' } },
    });
    shopifyAPI.connect.mockRejectedValue(new Error('Shopify error'));
    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.get('button').text()).toMatch(/RECONNECT$/);
    await wrapper.get('button').trigger('click');

    expect(shopifyAPI.connect).toHaveBeenCalledWith('shop.myshopify.com');
  });

  it('keeps the selection available to retry when saving fails', async () => {
    shopifyAPI.saveStorefrontWidget.mockRejectedValue(
      new Error('Shopify error')
    );
    const wrapper = mountComponent();
    await flushPromises();

    await wrapper.get('select').setValue('21');
    await wrapper.get('form').trigger('submit');
    await flushPromises();

    expect(mocks.alert).toHaveBeenCalled();
    expect(wrapper.get('select').element.value).toBe('21');
    expect(wrapper.find('a').exists()).toBe(false);
  });
});
