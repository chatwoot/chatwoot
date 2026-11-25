import { describe, it, expect, beforeEach, vi } from 'vitest';
import { defineComponent } from 'vue';
import { mount, flushPromises } from '@vue/test-utils';
import WhatsappChannel from 'dashboard/api/channel/whatsappChannel';
import ZapiWebhookUrl from '../ZapiWebhookUrl.vue';

vi.mock('vue-i18n', async () => {
  const actual = await vi.importActual('vue-i18n');
  return { ...actual, useI18n: () => ({ t: key => key }) };
});

const mockAlert = vi.fn();
vi.mock('dashboard/composables', () => ({
  useAlert: (...args) => mockAlert(...args),
}));

vi.mock('dashboard/api/channel/whatsappChannel', () => ({
  default: { rotateZapiWebhookUrl: vi.fn() },
}));

const mountSection = () =>
  mount(ZapiWebhookUrl, {
    props: { inbox: { id: 7, provider: 'zapi', provider_config: {} } },
    global: {
      stubs: {
        SettingsSection: defineComponent({
          name: 'SettingsSection',
          template: '<div><slot /></div>',
        }),
      },
    },
  });

describe('ZapiWebhookUrl', () => {
  beforeEach(() => {
    mockAlert.mockReset();
    WhatsappChannel.rotateZapiWebhookUrl.mockReset();
  });

  it('asks the server for a new address for this inbox', async () => {
    WhatsappChannel.rotateZapiWebhookUrl.mockResolvedValue({});
    const wrapper = mountSection();

    await wrapper
      .find('[data-test-id="rotate-zapi-webhook-url"]')
      .trigger('click');
    await flushPromises();

    expect(WhatsappChannel.rotateZapiWebhookUrl).toHaveBeenCalledWith(7);
    expect(mockAlert).toHaveBeenCalledWith(
      'INBOX_MGMT.SETTINGS_POPUP.ZAPI_WEBHOOK_URL.SUCCESS'
    );
  });

  it('says the inbox keeps the current address when Z-API refuses', async () => {
    WhatsappChannel.rotateZapiWebhookUrl.mockRejectedValue(new Error('422'));
    const wrapper = mountSection();

    await wrapper
      .find('[data-test-id="rotate-zapi-webhook-url"]')
      .trigger('click');
    await flushPromises();

    expect(mockAlert).toHaveBeenCalledWith(
      'INBOX_MGMT.SETTINGS_POPUP.ZAPI_WEBHOOK_URL.ERROR'
    );
  });
});
