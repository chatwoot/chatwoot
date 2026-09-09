import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import ConfigurationPage from '../ConfigurationPage.vue';

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

vi.mock('dashboard/composables/useWhatsappEmbeddedSignup', () => ({
  useWhatsappEmbeddedSignup: () => ({
    runEmbeddedSignup: vi.fn(),
  }),
}));

const mountComponent = inbox =>
  shallowMount(ConfigurationPage, {
    props: { inbox },
    global: {
      plugins: [
        createStore({
          getters: {
            'globalConfig/isOnChatwootCloud': () => true,
          },
        }),
      ],
      mocks: {
        $t: key => key,
      },
      stubs: {
        SettingsFieldSection: {
          template: '<section><slot /></section>',
        },
        NextButton: {
          template: '<button><slot /></button>',
        },
        'woot-code': true,
        'woot-input': true,
        WhatsappBusinessManagementToken: true,
      },
    },
  });

describe('ConfigurationPage', () => {
  it('shows the WhatsApp reconfigure option for embedded signup inboxes without checking account feature flags', () => {
    const wrapper = mountComponent({
      channel_type: 'Channel::Whatsapp',
      provider: 'whatsapp_cloud',
      provider_config: {
        source: 'embedded_signup',
        webhook_verify_token: 'verify-token',
      },
    });

    expect(wrapper.vm.showWhatsAppReconfigure).toBe(true);
    expect(wrapper.text()).toContain(
      'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_RECONFIGURE_BUTTON'
    );
  });

  it('does not show the WhatsApp reconfigure option for manual WhatsApp inboxes', () => {
    const wrapper = mountComponent({
      channel_type: 'Channel::Whatsapp',
      provider: 'whatsapp_cloud',
      provider_config: {
        source: 'manual_setup_v2',
        webhook_verify_token: 'verify-token',
      },
    });

    expect(wrapper.vm.showWhatsAppReconfigure).toBe(false);
  });
});
