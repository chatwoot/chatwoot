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
});
