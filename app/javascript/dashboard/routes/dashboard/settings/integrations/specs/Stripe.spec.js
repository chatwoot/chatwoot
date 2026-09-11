import { mount, flushPromises } from '@vue/test-utils';
import Stripe from '../Stripe.vue';
import StripeAPI from 'dashboard/api/integrations/stripe';
import messages from 'dashboard/i18n/locale/en/en.json';

const mocks = vi.hoisted(() => ({
  dispatch: vi.fn(),
  enabled: true,
  query: {},
  installationName: undefined,
}));

vi.mock('vue-router', () => ({ useRoute: () => ({ query: mocks.query }) }));
vi.mock(
  'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue',
  () => ({
    default: { template: '<header />' },
  })
);
vi.mock('dashboard/composables/store', async () => {
  const { computed } = await import('vue');
  return {
    useStore: () => ({ dispatch: mocks.dispatch }),
    useFunctionGetter: () => computed(() => ({ enabled: mocks.enabled })),
    useMapGetter: () =>
      computed(() => ({ installationName: mocks.installationName })),
  };
});
vi.mock('dashboard/api/integrations/stripe', () => ({
  default: { get: vi.fn(), connect: vi.fn(), disconnect: vi.fn() },
}));

describe('Stripe integration settings', () => {
  let wrapper;
  const global = {
    stubs: {
      SettingsLayout: {
        template: '<div><slot name="header"/><slot name="body"/></div>',
      },
      BaseSettingsHeader: true,
    },
  };

  beforeEach(() => {
    mocks.enabled = true;
    mocks.query = {};
    mocks.installationName = undefined;
    mocks.dispatch.mockResolvedValue();
    StripeAPI.get.mockResolvedValue({
      data: {
        account_id: 'acct_test',
        connected_at: '2026-09-10T00:00:00Z',
        mode: 'sandbox',
      },
    });
  });
  afterEach(() => wrapper?.unmount());

  it.each(['Acme Support', undefined])(
    'uses installation branding in disconnect copy: %s',
    async installationName => {
      mocks.installationName = installationName;
      wrapper = mount(Stripe, {
        global: {
          ...global,
          mocks: {
            $t: key => messages.STRIPE_INTEGRATION[key.split('.')[1]] || key,
          },
        },
      });
      await flushPromises();
      const brand = installationName || 'Chatwoot';
      expect(wrapper.get('button').text()).toBe(`Disconnect from ${brand}`);
      expect(wrapper.text()).toContain(
        `Disconnecting removes the saved credentials from ${brand}.`
      );
      if (installationName) expect(wrapper.text()).not.toContain('Chatwoot');
    }
  );

  it('shows connected account details and a sandbox dashboard link', async () => {
    wrapper = mount(Stripe, { global });
    await flushPromises();
    expect(mocks.dispatch).toHaveBeenCalledWith('integrations/get', 'stripe');
    expect(wrapper.text()).toContain('acct_test');
    expect(wrapper.text()).toContain('STRIPE_INTEGRATION.CONNECTED');
    expect(wrapper.get('a').attributes('href')).toBe(
      'https://dashboard.stripe.com/acct_test/test/dashboard'
    );
    expect(wrapper.get('a').attributes('rel')).toBe('noopener noreferrer');
  });

  it('does not request account details when disconnected', async () => {
    mocks.enabled = false;
    wrapper = mount(Stripe, { global });
    await flushPromises();
    expect(StripeAPI.get).not.toHaveBeenCalled();
    expect(wrapper.get('button').text()).toContain(
      'STRIPE_INTEGRATION.CONNECT'
    );
    expect(wrapper.find('a').exists()).toBe(false);
  });

  it('shows live mode and links to the live dashboard', async () => {
    StripeAPI.get.mockResolvedValue({
      data: {
        account_id: 'acct_live',
        connected_at: '2026-09-10T00:00:00Z',
        mode: 'live',
      },
    });
    wrapper = mount(Stripe, { global });
    await flushPromises();
    expect(wrapper.text()).toContain('STRIPE_INTEGRATION.LIVE');
    expect(wrapper.text()).not.toContain('STRIPE_INTEGRATION.SANDBOX');
    expect(wrapper.get('a').attributes('href')).toBe(
      'https://dashboard.stripe.com/acct_live/dashboard'
    );
  });

  it('shows a safe error if account details cannot load', async () => {
    StripeAPI.get.mockRejectedValue(new Error('private provider details'));
    wrapper = mount(Stripe, { global });
    await flushPromises();
    expect(wrapper.get('[role="alert"]').text()).toContain(
      'STRIPE_INTEGRATION.ERROR'
    );
    expect(wrapper.text()).not.toContain('private provider details');
  });

  it('shows a failed OAuth callback error', async () => {
    mocks.query = { error: 'authorization_failed' };
    wrapper = mount(Stripe, { global });
    await flushPromises();
    expect(wrapper.get('[role="alert"]').exists()).toBe(true);
  });

  it('keeps the connected account visible when disconnect fails', async () => {
    StripeAPI.disconnect.mockRejectedValue(new Error('request failed'));
    wrapper = mount(Stripe, { global });
    await flushPromises();
    await wrapper.get('button').trigger('click');
    await flushPromises();
    expect(StripeAPI.disconnect).toHaveBeenCalledOnce();
    expect(wrapper.text()).toContain('acct_test');
    expect(wrapper.get('[role="alert"]').exists()).toBe(true);
  });
});
