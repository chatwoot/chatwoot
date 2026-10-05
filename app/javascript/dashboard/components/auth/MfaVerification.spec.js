import { shallowMount, flushPromises } from '@vue/test-utils';
import { ref } from 'vue';
import axios from 'axios';

import MfaVerification from './MfaVerification.vue';
import {
  clearLocalStorageOnLogout,
  setAuthCredentials,
} from 'dashboard/store/utils/api';

vi.mock('axios');
vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ isOnChatwootCloud: ref(false) }),
}));
vi.mock('dashboard/store/utils/api', () => ({
  clearLocalStorageOnLogout: vi.fn(),
  parseAPIErrorResponse: vi.fn(),
  setAuthCredentials: vi.fn(),
}));

describe('MfaVerification', () => {
  it('returns the authenticated user to the login flow after verification', async () => {
    const user = { id: 1, accounts: [{ id: 2 }] };
    const response = {
      data: { data: user },
      headers: { 'access-token': 'token' },
    };
    axios.post.mockResolvedValue(response);
    const wrapper = shallowMount(MfaVerification, {
      props: { mfaToken: 'mfa-token' },
      global: {
        mocks: { $t: key => key },
      },
    });

    const inputs = wrapper.findAll('input');
    await inputs[0].setValue('1');
    await inputs[1].setValue('2');
    await inputs[2].setValue('3');
    await inputs[3].setValue('4');
    await inputs[4].setValue('5');
    await inputs[5].setValue('6');
    await flushPromises();

    expect(setAuthCredentials).toHaveBeenCalledWith(response);
    expect(clearLocalStorageOnLogout).toHaveBeenCalledTimes(1);
    expect(wrapper.emitted('verified')).toEqual([[user]]);
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

  it('hands a 206 setup challenge to the parent instead of treating it as auth', async () => {
    const response = {
      status: 206,
      data: {
        mfa_setup_required: true,
        mfa_setup_token: 'setup-token',
        provisioning_url: 'otpauth://totp/x',
        secret: 'SECRET',
      },
      headers: {},
    };
    axios.post.mockResolvedValue(response);

    const wrapper = shallowMount(MfaVerification, {
      props: { mfaToken: 'mfa-token', verificationChannel: 'email' },
      global: { mocks: { $t: key => key } },
    });

    const otpInputs = wrapper.findAll('input[inputmode="numeric"]');
    for (let i = 0; i < 6; i += 1) {
      // eslint-disable-next-line no-await-in-loop
      await otpInputs[i].setValue(String(i + 1));
    }
    await flushPromises();

    expect(setAuthCredentials).not.toHaveBeenCalled();
    expect(wrapper.emitted('verified')).toBeUndefined();
    expect(wrapper.emitted('setupRequired')).toEqual([[response.data]]);
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
