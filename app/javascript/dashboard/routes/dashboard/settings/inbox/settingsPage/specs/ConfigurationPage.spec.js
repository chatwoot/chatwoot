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
  it('keeps IMAP settings available after IMAP is disabled', async () => {
    const inbox = {
      channel_type: 'Channel::Email',
      forwarding_enabled: true,
      imap_enabled: true,
      imap_address: 'imap.example.com',
    };
    const wrapper = mountComponent(inbox);
    await wrapper.setProps({ inbox: { ...inbox, imap_enabled: false } });

    expect(wrapper.findComponent({ name: 'ImapSettings' }).exists()).toBe(true);
  });

  it('hides IMAP settings for a forwarding-only inbox', () => {
    const wrapper = mountComponent({
      channel_type: 'Channel::Email',
      forwarding_enabled: true,
      imap_enabled: false,
      imap_address: '',
    });

    expect(wrapper.findComponent({ name: 'ImapSettings' }).exists()).toBe(
      false
    );
    expect(wrapper.findComponent({ name: 'SmtpSettings' }).exists()).toBe(true);
  });

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
