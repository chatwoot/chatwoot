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
});
