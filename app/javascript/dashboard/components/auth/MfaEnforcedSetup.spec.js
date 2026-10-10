import { flushPromises, shallowMount } from '@vue/test-utils';
import axios from 'axios';
import {
  parseAPIErrorResponse,
  setAuthCredentials,
} from 'dashboard/store/utils/api';
import MfaEnforcedSetup from './MfaEnforcedSetup.vue';

vi.mock('axios');

vi.mock('dashboard/store/utils/api', () => ({
  parseAPIErrorResponse: vi.fn(),
  setAuthCredentials: vi.fn(),
}));

const handleVerificationError = vi.fn();
const MfaSetupWizard = {
  name: 'MfaSetupWizard',
  template: '<div />',
  props: [
    'showSetup',
    'mfaEnabled',
    'provisioningUri',
    'secretKey',
    'backupCodes',
  ],
  methods: { handleVerificationError },
};

const mountComponent = () =>
  shallowMount(MfaEnforcedSetup, {
    props: {
      mfaSetupToken: 'setup-token',
      provisioningUrl: 'otpauth://totp/Chatwoot:user@example.com?secret=ABC',
      secret: 'ABC',
    },
    global: {
      mocks: { $t: key => key },
      stubs: { MfaSetupWizard },
    },
  });

describe('MfaEnforcedSetup', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('activates mfa and stores credentials on successful verification', async () => {
    const response = {
      data: {
        data: { id: 1 },
        backup_codes: ['CODE1', 'CODE2'],
      },
      headers: { 'access-token': 'token' },
    };
    axios.post.mockResolvedValue(response);

    const wrapper = mountComponent();
    const wizard = wrapper.findComponent(MfaSetupWizard);
    wizard.vm.$emit('verify', '123456');
    await flushPromises();

    expect(axios.post).toHaveBeenCalledWith('/auth/sign_in', {
      mfa_setup_token: 'setup-token',
      otp_code: '123456',
    });
    expect(wizard.props('backupCodes')).toEqual(['CODE1', 'CODE2']);
    expect(setAuthCredentials).not.toHaveBeenCalled();
    expect(wrapper.emitted('verified')).toBeUndefined();

    wizard.vm.$emit('complete');
    await flushPromises();

    expect(setAuthCredentials).toHaveBeenCalledWith(response);
    expect(wrapper.emitted('verified')).toHaveLength(1);
    expect(wrapper.emitted('verified')[0]).toEqual([response.data]);
  });

  it('reports the error to the wizard on failed verification', async () => {
    const error = {
      response: { data: { error: 'Invalid verification code' } },
    };
    axios.post.mockRejectedValue(error);
    parseAPIErrorResponse.mockReturnValue('Invalid verification code');

    const wrapper = mountComponent();
    const wizard = wrapper.findComponent(MfaSetupWizard);
    wizard.vm.$emit('verify', '000000');
    await flushPromises();

    expect(handleVerificationError).toHaveBeenCalledWith(
      'Invalid verification code'
    );
    expect(setAuthCredentials).not.toHaveBeenCalled();
    expect(wrapper.emitted('verified')).toBeUndefined();
  });

  it('never emits verified without a stored auth response', async () => {
    const wrapper = mountComponent();
    const wizard = wrapper.findComponent(MfaSetupWizard);
    wizard.vm.$emit('complete');
    await flushPromises();

    expect(setAuthCredentials).not.toHaveBeenCalled();
    expect(wrapper.emitted('verified')).toBeUndefined();
  });
});
