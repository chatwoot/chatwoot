import { flushPromises, mount } from '@vue/test-utils';
import { ref } from 'vue';
import { createMemoryHistory, createRouter } from 'vue-router';
import InboxSetup from '../InboxSetup.vue';
import instagramClient from 'dashboard/api/channel/instagramClient';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
  useTrack: vi.fn(),
}));
vi.mock('dashboard/composables/store', () => ({
  useStore: () => ({ dispatch: vi.fn() }),
  useMapGetter: () => ref([]),
}));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({
    accountId: ref(1),
    currentAccount: ref({}),
    finishOnboarding: vi.fn(),
    isMetaInboxCreationDisabled: ref(false),
  }),
}));
vi.mock('dashboard/composables/useConfig', () => ({
  useConfig: () => ({ isEnterprise: ref(false) }),
}));
vi.mock('../inbox-setup/useChannelConnect', () => ({
  useChannelConnect: () => ({
    connectViaOAuth: vi.fn(),
    connectWhatsapp: vi.fn(),
  }),
}));
vi.mock('../inbox-setup/useDetectedChannels', () => ({
  useDetectedChannels: () => ({
    displayedChannels: ref([]),
    remainingChannels: ref([]),
    connectedInbox: vi.fn(),
    hasDetectedChannels: ref(false),
  }),
}));
vi.mock('dashboard/api/channel/instagramClient', () => ({
  default: { fetchAccounts: vi.fn(), connectAccount: vi.fn() },
}));

const onboardingPath = '/app/accounts/1/onboarding/inbox-setup';
const accounts = [
  { id: 'ig1', username: 'first' },
  { id: 'ig2', username: 'second' },
];

const mountOnboarding = async () => {
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      {
        path: '/app/accounts/:accountId/onboarding/inbox-setup',
        component: InboxSetup,
      },
    ],
  });
  await router.push(
    `${onboardingPath}?connection_token=pending-connection&source=instagram`
  );
  await router.isReady();
  const wrapper = mount(InboxSetup, {
    global: {
      plugins: [router],
      stubs: {
        OnboardingLayout: { template: '<div><slot /></div>' },
        OnboardingSection: { template: '<section><slot /></section>' },
        WebWidgetCreationStatus: true,
        HelpCenterCreationStatus: true,
        InboxChannelsDialog: true,
        InboxChannelsFooter: true,
        ChannelRow: true,
        Icon: true,
        Spinner: true,
      },
    },
  });
  await flushPromises();
  return { wrapper, router };
};

describe('Instagram connections during onboarding', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    Object.defineProperty(window, 'location', {
      configurable: true,
      writable: true,
      value: { href: '' },
    });
    instagramClient.connectAccount.mockResolvedValue({
      data: { redirect_url: onboardingPath },
    });
  });

  it('automatically connects a single account from the onboarding callback', async () => {
    instagramClient.fetchAccounts.mockResolvedValue({
      data: { accounts: [accounts[0]] },
    });
    await mountOnboarding();

    expect(instagramClient.fetchAccounts).toHaveBeenCalledWith(
      'pending-connection'
    );
    expect(instagramClient.connectAccount).toHaveBeenCalledWith(
      'pending-connection',
      'ig1'
    );
    expect(window.location.href).toBe(onboardingPath);
  });

  it('lets the administrator choose among multiple accounts without leaving onboarding', async () => {
    instagramClient.fetchAccounts.mockResolvedValue({ data: { accounts } });
    const { wrapper, router } = await mountOnboarding();
    expect(instagramClient.connectAccount).not.toHaveBeenCalled();
    expect(router.currentRoute.value.path).toBe(onboardingPath);

    await wrapper.find('select').setValue('ig2');
    await wrapper.find('button').trigger('click');
    await flushPromises();

    expect(instagramClient.connectAccount).toHaveBeenCalledWith(
      'pending-connection',
      'ig2'
    );
    expect(window.location.href).toBe(onboardingPath);
  });

  it('shows expiration errors and removes only the connection token when cancelled', async () => {
    instagramClient.fetchAccounts.mockRejectedValue({
      response: { data: { error: 'Connection expired' } },
    });
    const { wrapper, router } = await mountOnboarding();
    expect(wrapper.find('[role="alert"]').text()).toBe('Connection expired');

    await wrapper.findAll('button').at(-1).trigger('click');
    await flushPromises();

    expect(router.currentRoute.value.query).toEqual({ source: 'instagram' });
    expect(wrapper.find('[role="alert"]').exists()).toBe(false);
    expect(instagramClient.connectAccount).not.toHaveBeenCalled();
  });
});
