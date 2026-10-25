import { shallowMount } from '@vue/test-utils';
import { ref } from 'vue';
import Email from '../Email.vue';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';
import PageHeader from '../../../SettingsSubPageHeader.vue';
import inboxMgmt from 'dashboard/i18n/locale/en/inboxMgmt.json';

const account = ref({ features: { inbound_emails: true }, domain: '' });
const globalConfig = ref({ inboundEmailDomainPresent: false });

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ currentAccount: account }),
}));
vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => globalConfig,
  useStoreGetters: () => ({
    'globalConfig/get': globalConfig,
    'globalConfig/isAChatwootInstance': ref(false),
  }),
}));

describe('Email provider selection', () => {
  beforeEach(() => {
    window.chatwootConfig = {};
  });

  it('uses the installation name in the provider description', () => {
    globalConfig.value = { installationName: 'Acme Support' };
    const wrapper = shallowMount(Email, {
      global: {
        mocks: {
          $t: key =>
            key.split('.').reduce((value, part) => value[part], inboxMgmt),
        },
      },
    });

    expect(wrapper.findComponent(PageHeader).props('headerContent')).toBe(
      'Connect a provider, use IMAP/SMTP, or forward emails to Acme Support.'
    );
  });

  it.each([
    ['', false, true, false],
    ['mail.example.com', false, true, true],
    ['', true, true, true],
    ['mail.example.com', true, false, false],
  ])(
    'checks account and installation forwarding configuration',
    (domain, installationDomain, enabled, expected) => {
      account.value = { domain, features: { inbound_emails: enabled } };
      globalConfig.value = { inboundEmailDomainPresent: installationDomain };
      const wrapper = shallowMount(Email, {
        global: { mocks: { $t: key => key } },
      });
      const forwarding = wrapper
        .findAllComponents(ChannelSelector)
        .find(card => card.props('icon') === 'i-lucide-forward');
      expect(forwarding.vm.$attrs.disabled).toBe(!expected);
    }
  );
});
