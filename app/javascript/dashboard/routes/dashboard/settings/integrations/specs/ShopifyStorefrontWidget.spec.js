import { flushPromises, mount } from '@vue/test-utils';
import shopifyAPI from 'dashboard/api/integrations/shopify';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import ShopifyStorefrontWidget from '../ShopifyStorefrontWidget.vue';

const mocks = vi.hoisted(() => ({
  dispatch: vi.fn(),
  inboxes: [
    { id: 21, name: 'Store support' },
    { id: 22, name: 'Returns' },
  ],
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
        OnClickOutside: { template: '<div><slot /></div>' },
        TeleportWithDirection: { template: '<div><slot /></div>' },
        WootLoadingState: true,
      },
    },
  });

const openInboxDialog = async wrapper => {
  const dialog = wrapper.get('dialog').element;
  dialog.showModal = () => dialog.setAttribute('open', '');
  dialog.close = () => dialog.removeAttribute('open');
  await wrapper.get('button:not(dialog button)').trigger('click');
};

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
    await openInboxDialog(wrapper);
    const picker = wrapper.getComponent(ComboBox);
    await picker.get('button').trigger('click');
    await picker.get('[role="option"]').trigger('click');
    await wrapper.get('form').trigger('submit');
    await flushPromises();

    expect(shopifyAPI.saveStorefrontWidget).toHaveBeenCalledWith(21);
    expect(wrapper.get('a').attributes('href')).toBe(themeEditorUrl);
  });

  it('shows the saved inbox and restores it when a change is cancelled', async () => {
    shopifyAPI.getStorefrontWidget.mockResolvedValue({
      data: { inbox_id: 21, theme_editor_url: themeEditorUrl },
    });
    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.text()).toContain('Store support');
    expect(wrapper.findComponent(ComboBox).exists()).toBe(false);
    expect(wrapper.get('a').attributes('href')).toBe(themeEditorUrl);

    await openInboxDialog(wrapper);
    expect(wrapper.getComponent(ComboBox).get('button').text()).toBe(
      'Store support'
    );
    expect(wrapper.get('dialog button[type="submit"]').element.disabled).toBe(
      true
    );
    const picker = wrapper.getComponent(ComboBox);
    await picker.get('button').trigger('click');
    await picker.get('input[type="search"]').setValue('return');
    const option = picker.get('[role="option"]');
    expect(option.text()).toBe('Returns');
    await option.trigger('click');
    expect(wrapper.get('dialog button[type="submit"]').element.disabled).toBe(
      false
    );
    await wrapper.get('dialog button[type="button"]').trigger('click');

    expect(wrapper.findComponent(ComboBox).exists()).toBe(false);
    expect(wrapper.get('a').attributes('href')).toBe(themeEditorUrl);
    expect(shopifyAPI.saveStorefrontWidget).not.toHaveBeenCalled();
    await openInboxDialog(wrapper);
    expect(wrapper.getComponent(ComboBox).get('button').text()).toBe(
      'Store support'
    );
  });

  it('explains where to add a Website inbox when none exist', async () => {
    const inboxes = mocks.inboxes;
    mocks.inboxes = [];
    const wrapper = mountComponent();
    mocks.inboxes = inboxes;
    await flushPromises();

    expect(wrapper.text()).toContain('STOREFRONT_WIDGET.NO_INBOXES');
    expect(wrapper.find('button:not(dialog button)').exists()).toBe(false);
    expect(wrapper.find('a').exists()).toBe(false);
  });

  it('offers to reconnect the existing store when Shopify rejects the token', async () => {
    shopifyAPI.getStorefrontWidget.mockRejectedValue({
      response: { data: { code: 'shopify_reauthorization_required' } },
    });
    shopifyAPI.connect.mockRejectedValue(new Error('Shopify error'));
    const wrapper = mountComponent();
    await flushPromises();

    expect(wrapper.get('button:not(dialog button)').text()).toMatch(
      /RECONNECT$/
    );
    await wrapper.get('button:not(dialog button)').trigger('click');

    expect(shopifyAPI.connect).toHaveBeenCalledWith('shop.myshopify.com');
  });

  it('keeps the selection available to retry when saving fails', async () => {
    shopifyAPI.saveStorefrontWidget.mockRejectedValue(
      new Error('Shopify error')
    );
    const wrapper = mountComponent();
    await flushPromises();

    await openInboxDialog(wrapper);
    const picker = wrapper.getComponent(ComboBox);
    await picker.get('button').trigger('click');
    await picker.get('[role="option"]').trigger('click');
    await wrapper.get('form').trigger('submit');
    await flushPromises();

    expect(mocks.alert).toHaveBeenCalled();
    expect(wrapper.getComponent(ComboBox).get('button').text()).toBe(
      'Store support'
    );
    expect(wrapper.find('a').exists()).toBe(false);
  });
});
