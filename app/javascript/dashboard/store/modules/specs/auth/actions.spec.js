import axios from 'axios';
import { actions } from '../../auth';
import * as types from '../../../mutation-types';
import { setUser, clearCookiesOnLogout } from '../../../utils/api';

import '../../../../routes';

jest.mock('../../../../routes', () => {});
jest.mock('../../../utils/api', () => ({
  setUser: jest.fn(),
  clearCookiesOnLogout: jest.fn(),
  getHeaderExpiry: jest.fn(),
}));

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#validityCheck', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { data: { id: 1, name: 'John' } } },
        headers: { expiry: 581842904 },
      });
      await actions.validityCheck({ commit });
      expect(setUser).toHaveBeenCalledTimes(1);
      expect(commit.mock.calls).toEqual([[types.default.SET_CURRENT_USER]]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({
        response: { status: 401 },
      });
      await actions.validityCheck({ commit });
      expect(clearCookiesOnLogout);
    });
  });
});
