import { shallowMount } from '@vue/test-utils';
import { ref } from 'vue';
import Email from '../Email.vue';
import ChannelSelector from 'dashboard/components/ChannelSelector.vue';

const account = ref({ features: { inbound_emails: true }, domain: '' });
const globalConfig = ref({ inboundEmailDomainPresent: false });

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ currentAccount: account }),
}));
vi.mock('dashboard/composables/store', () => ({
  useStoreGetters: () => ({
    'globalConfig/get': globalConfig,
    'globalConfig/isAChatwootInstance': ref(false),
  }),
}));

describe('Email provider selection', () => {
  beforeEach(() => {
    window.chatwootConfig = {};
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
