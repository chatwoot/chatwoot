import { flushPromises, shallowMount } from '@vue/test-utils';
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
  it('stores persistent credentials and returns the authenticated user to the login flow', async () => {
    const user = { id: 1, accounts: [{ id: 2 }] };
    const response = {
      data: { data: user },
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
      global: {
        mocks: { $t: key => key },
      },
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
    expect(clearLocalStorageOnLogout).toHaveBeenCalledTimes(1);
    expect(wrapper.emitted('verified')).toEqual([[user]]);
  });
});
