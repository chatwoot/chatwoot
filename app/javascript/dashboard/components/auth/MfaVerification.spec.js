import { flushPromises, shallowMount } from '@vue/test-utils';
import axios from 'axios';
import { setAuthCredentials } from 'dashboard/store/utils/api';
import MfaVerification from './MfaVerification.vue';

vi.mock('axios');

vi.mock('dashboard/store/utils/api', () => ({
  parseAPIErrorResponse: vi.fn(),
  setAuthCredentials: vi.fn(),
}));

vi.mock('dashboard/composables/useAccount', async () => {
  const { ref } = await import('vue');
  return { useAccount: () => ({ isOnChatwootCloud: ref(true) }) };
});

describe('MfaVerification', () => {
  it('stores successful MFA credentials using the persistent auth flow', async () => {
    const response = {
      data: { data: { id: 1 } },
      headers: {
        'access-token': 'token',
        'token-type': 'Bearer',
        client: 'client',
        expiry: '1789084800',
        uid: 'user@example.com',
      },
    };
    axios.post.mockResolvedValue(response);

    const wrapper = shallowMount(MfaVerification, {
      props: { mfaToken: 'mfa-token' },
      global: { mocks: { $t: key => key } },
    });

    const otpInputs = wrapper.findAll('input[inputmode="numeric"]');
    await otpInputs[0].setValue('1');
    await otpInputs[1].setValue('2');
    await otpInputs[2].setValue('3');
    await otpInputs[3].setValue('4');
    await otpInputs[4].setValue('5');
    await otpInputs[5].setValue('6');
    await flushPromises();

    expect(axios.post).toHaveBeenCalledWith('/auth/sign_in', {
      mfa_token: 'mfa-token',
      otp_code: '123456',
    });
    expect(setAuthCredentials).toHaveBeenCalledWith(response);
    expect(wrapper.emitted('verified')).toEqual([[response.data]]);
  });

  it('shows email copy and hides TOTP-only affordances for the email channel', () => {
    const wrapper = shallowMount(MfaVerification, {
      props: { mfaToken: 'mfa-token', verificationChannel: 'email' },
      global: { mocks: { $t: key => key } },
    });

    expect(wrapper.text()).toContain('MFA_VERIFICATION.EMAIL_TITLE');
    expect(wrapper.text()).toContain('MFA_VERIFICATION.ENTER_EMAIL_CODE');
    expect(wrapper.text()).not.toContain('MFA_VERIFICATION.AUTHENTICATOR_APP');
    expect(wrapper.text()).not.toContain('MFA_VERIFICATION.BACKUP_CODE');
    expect(wrapper.html()).not.toContain('MFA_VERIFICATION.TRY_ANOTHER_METHOD');
    expect(wrapper.html()).not.toContain('MFA_VERIFICATION.HELP_TEXT');
    expect(wrapper.findAll('input[inputmode="numeric"]')).toHaveLength(6);
  });

  it('keeps the classic MFA UI when no verification channel is set', () => {
    const wrapper = shallowMount(MfaVerification, {
      props: { mfaToken: 'mfa-token' },
      global: { mocks: { $t: key => key } },
    });

    expect(wrapper.text()).toContain('MFA_VERIFICATION.TITLE');
    expect(wrapper.text()).toContain('MFA_VERIFICATION.AUTHENTICATOR_APP');
    expect(wrapper.html()).toContain('MFA_VERIFICATION.TRY_ANOTHER_METHOD');
  });

  it('shows a default-checked trust-device box for the email channel and sends it', async () => {
    const response = {
      data: { data: { id: 1 } },
      headers: {
        'access-token': 't',
        client: 'c',
        expiry: '1',
        uid: 'u@example.com',
      },
    };
    axios.post.mockResolvedValue(response);

    const wrapper = shallowMount(MfaVerification, {
      props: { mfaToken: 'mfa-token', verificationChannel: 'email' },
      global: { mocks: { $t: key => key } },
    });

    const checkbox = wrapper.find('[data-testid="remember_device"]');
    expect(checkbox.exists()).toBe(true);
    expect(checkbox.element.checked).toBe(true);

    const otpInputs = wrapper.findAll('input[inputmode="numeric"]');
    for (let i = 0; i < 6; i += 1) {
      // eslint-disable-next-line no-await-in-loop
      await otpInputs[i].setValue(String(i + 1));
    }
    await flushPromises();

    expect(axios.post).toHaveBeenCalledWith('/auth/sign_in', {
      mfa_token: 'mfa-token',
      otp_code: '123456',
      remember_device: true,
    });
  });

  it('does not show the trust-device box on the classic MFA channel', () => {
    const wrapper = shallowMount(MfaVerification, {
      props: { mfaToken: 'mfa-token' },
      global: { mocks: { $t: key => key } },
    });
    expect(wrapper.find('[data-testid="remember_device"]').exists()).toBe(
      false
    );
  });
});
