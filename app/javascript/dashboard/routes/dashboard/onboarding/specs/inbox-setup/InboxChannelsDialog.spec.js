import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import InboxChannelsDialog from '../../inbox-setup/InboxChannelsDialog.vue';

const { isOnChatwootCloud, isMetaInboxCreationDisabled, isTiktokEnabled } =
  vi.hoisted(() => ({
    isOnChatwootCloud: { value: false },
    isMetaInboxCreationDisabled: { value: false },
    isTiktokEnabled: { value: true },
  }));

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables/store', () => ({
  useMapGetter: getter =>
    getter === 'globalConfig/isOnChatwootCloud'
      ? isOnChatwootCloud
      : { value: {} },
}));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({
    isCloudFeatureEnabled: feature =>
      feature !== 'channel_tiktok' || isTiktokEnabled.value,
    isOnChatwootCloud,
    isMetaInboxCreationDisabled,
  }),
}));
vi.mock('../../inbox-setup/useChannelConnect', () => ({
  useChannelConnect: () => ({
    connectViaOAuth: vi.fn(),
    connectWhatsapp: vi.fn(),
  }),
}));

const mountDialog = () =>
  mount(InboxChannelsDialog, {
    props: { inboxes: [] },
    global: {
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

describe('InboxChannelsDialog channel availability', () => {
  afterEach(() => {
    delete window.chatwootConfig;
    isOnChatwootCloud.value = false;
    isMetaInboxCreationDisabled.value = false;
    isTiktokEnabled.value = true;
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

  it('shows the grid when Meta inbox creation is disabled on Chatwoot Cloud', async () => {
    isOnChatwootCloud.value = true;
    isMetaInboxCreationDisabled.value = true;
    window.chatwootConfig = { fbAppId: 'fb-app' };
    const wrapper = mountDialog();

    wrapper.vm.open('facebook');
    await nextTick();

    expect(wrapper.find('[data-test="fb-form"]').exists()).toBe(false);
    expect(wrapper.find('button').exists()).toBe(true);
  });

  it('shows TikTok as disabled when account access is disabled on Chatwoot Cloud', () => {
    isOnChatwootCloud.value = true;
    isTiktokEnabled.value = false;
    window.chatwootConfig = { tiktokAppId: 'tiktok-app' };
    const wrapper = mountDialog();

    const tiktokButton = wrapper
      .findAll('button')
      .find(button => button.text().includes('TIKTOK.TITLE'));

    expect(tiktokButton.attributes('disabled')).toBeDefined();
    expect(tiktokButton.text()).toContain('SETUP_LATER');
  });
});
