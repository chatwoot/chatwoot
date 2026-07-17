import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { createStore } from 'vuex';
import { useRoute } from 'vue-router';
import InboxChannelsDialog from '../../inbox-setup/InboxChannelsDialog.vue';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('vue-router');
vi.mock('../../inbox-setup/useChannelConnect', () => ({
  useChannelConnect: () => ({
    connectViaOAuth: vi.fn(),
    connectWhatsapp: vi.fn(),
  }),
}));

const store = createStore({
  modules: {
    globalConfig: {
      namespaced: true,
      getters: {
        get: () => ({}),
        isOnChatwootCloud: () => false,
      },
    },
    accounts: {
      namespaced: true,
      getters: {
        getAccount: () => () => ({ id: 1, features: {} }),
        isFeatureEnabledonAccount: () => () => false,
      },
    },
  },
});

const mountDialog = () =>
  mount(InboxChannelsDialog, {
    props: { inboxes: [] },
    global: {
      plugins: [store],
      stubs: {
        Dialog: {
          template: '<div><slot /></div>',
          methods: { open() {}, close() {} },
        },
        InboxFacebookForm: { template: '<div data-test="fb-form" />' },
        InboxChannelForm: { template: '<div data-test="channel-form" />' },
        ChannelIcon: true,
        Icon: true,
      },
    },
  });

describe('InboxChannelsDialog Facebook gating', () => {
  beforeEach(() => {
    useRoute.mockReturnValue({ params: { accountId: '1' } });
  });

  afterEach(() => {
    delete window.chatwootConfig;
  });

  it('opens the Facebook page picker when fbAppId is configured', async () => {
    window.chatwootConfig = { fbAppId: 'fb-app' };
    const wrapper = mountDialog();

    wrapper.vm.open('facebook');
    await nextTick();

    expect(wrapper.find('[data-test="fb-form"]').exists()).toBe(true);
  });

  it('shows the grid (not the picker) when fbAppId is missing', async () => {
    window.chatwootConfig = {};
    const wrapper = mountDialog();

    wrapper.vm.open('facebook');
    await nextTick();

    expect(wrapper.find('[data-test="fb-form"]').exists()).toBe(false);
    // The channel grid renders its cards instead.
    expect(wrapper.find('button').exists()).toBe(true);
  });
});
