import { shallowMount } from '@vue/test-utils';
import { ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import Whatsapp from '../channels/Whatsapp.vue';
import WhatsappEmbeddedSignup from '../channels/WhatsappEmbeddedSignup.vue';
import WhatsappManualSetup from '../channels/WhatsappManualSetup.vue';

vi.mock('vue-router');
vi.mock('dashboard/composables/useAccount');

describe('WhatsApp inbox setup', () => {
  const push = vi.fn();

  const mountSetup = ({
    quickSetupEnabled,
    query = { provider: 'whatsapp' },
  }) => {
    useRoute.mockReturnValue({ name: 'whatsapp', params: {}, query });
    useAccount.mockReturnValue({
      isOnChatwootCloud: ref(true),
      isMetaInboxCreationDisabled: ref(false),
      isCloudFeatureEnabled: flag =>
        flag === FEATURE_FLAGS.WHATSAPP_EMBEDDED_SIGNUP_FLOW &&
        quickSetupEnabled,
    });

    return shallowMount(Whatsapp);
  };

  beforeEach(() => {
    vi.stubGlobal('chatwootConfig', { whatsappAppId: 'test-app' });
    useRouter.mockReturnValue({ push });
    push.mockClear();
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('shows Quick setup directly to accounts with the flag', () => {
    const wrapper = mountSetup({ quickSetupEnabled: true });

    expect(wrapper.findComponent(WhatsappEmbeddedSignup).exists()).toBe(true);
  });

  it('shows manual setup without offering an access request when the flag is off', () => {
    const wrapper = mountSetup({ quickSetupEnabled: false });

    expect(wrapper.findComponent(WhatsappManualSetup).exists()).toBe(true);
    expect(wrapper.findComponent(WhatsappEmbeddedSignup).exists()).toBe(false);
    expect(
      wrapper.findComponent({ name: 'WhatsappAccessRequestDialog' }).exists()
    ).toBe(false);
  });

  it('describes the available setup and routes accounts without the flag to manual setup', () => {
    const wrapper = mountSetup({ quickSetupEnabled: false, query: {} });
    const cloudProvider = wrapper.findComponent({ name: 'ChannelSelector' });

    expect(cloudProvider.props('description')).toBe(
      'INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD_MANUAL_SETUP_DESC'
    );
    cloudProvider.vm.$emit('click');
    expect(push).toHaveBeenCalledWith({
      name: 'whatsapp',
      params: {},
      query: { provider: 'whatsapp_manual' },
    });
  });
});
