import axios from 'axios';
import Cookies from 'js-cookie';
import { actions } from '../../auth';
import types from '../../../mutation-types';
import * as APIHelpers from '../../../utils/api';
import '../../../../routes';

vi.spyOn(APIHelpers, 'setUser');
vi.spyOn(APIHelpers, 'clearCookiesOnLogout');
vi.spyOn(APIHelpers, 'getHeaderExpiry');
vi.spyOn(Cookies, 'get');

const commit = vi.fn();
const dispatch = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#validityCheck', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: { payload: { data: { id: 1, name: 'John' } } },
        headers: { expiry: 581842904 },
      });
      await actions.validityCheck({ commit });
      expect(APIHelpers.setUser).toHaveBeenCalledTimes(1);
      expect(commit.mock.calls).toEqual([
        [types.SET_CURRENT_USER, { id: 1, name: 'John' }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({
        response: { status: 401 },
      });
      await actions.validityCheck({ commit });
      expect(APIHelpers.clearCookiesOnLogout);
    });
  });

  describe('#updateProfile', () => {
    it('sends correct actions if API is success', async () => {
      axios.put.mockResolvedValue({
        data: { id: 1, name: 'John' },
        headers: { expiry: 581842904 },
      });
      await actions.updateProfile({ commit }, { name: 'Pranav' });
      expect(commit.mock.calls).toEqual([
        [types.SET_CURRENT_USER, { id: 1, name: 'John' }],
      ]);
    });
  });

  describe('#updateAvailability', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({
        data: {
          id: 1,
          name: 'John',
          accounts: [{ account_id: 1, availability_status: 'offline' }],
        },
        headers: { expiry: 581842904 },
      });
      await actions.updateAvailability(
        { commit, dispatch, getters: { getCurrentUserAvailability: 'online' } },
        { availability: 'offline', account_id: 1 }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_CURRENT_USER_AVAILABILITY, 'offline'],
        [
          types.SET_CURRENT_USER,
          {
            id: 1,
            name: 'John',
            accounts: [{ account_id: 1, availability_status: 'offline' }],
          },
        ],
      ]);
      expect(dispatch.mock.calls).toEqual([
        [
          'agents/updateSingleAgentPresence',
          { availabilityStatus: 'offline', id: 1 },
        ],
      ]);
    });

    it('sends correct actions if API is a failure', async () => {
      axios.post.mockRejectedValue({ error: 'Authentication Failure' });
      await actions.updateAvailability(
        { commit, dispatch, getters: { getCurrentUserAvailability: 'online' } },
        { availability: 'offline', account_id: 1 }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_CURRENT_USER_AVAILABILITY, 'offline'],
        [types.SET_CURRENT_USER_AVAILABILITY, 'online'],
      ]);
    });
  });

  describe('#updateAutoOffline', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({
        data: {
          id: 1,
          name: 'John',
          accounts: [
            {
              account_id: 1,
              auto_offline: false,
            },
          ],
        },
        headers: { expiry: 581842904 },
      });
      await actions.updateAutoOffline(
        { commit, dispatch, getters: { getCurrentUserAutoOffline: true } },
        { autoOffline: false, accountId: 1 }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_CURRENT_USER_AUTO_OFFLINE, false],
        [
          types.SET_CURRENT_USER,
          {
            id: 1,
            name: 'John',
            accounts: [{ account_id: 1, auto_offline: false }],
          },
        ],
      ]);
    });
    it('sends correct actions if API is failure', async () => {
      axios.post.mockRejectedValue({ error: 'Authentication Failure' });
      await actions.updateAutoOffline(
        { commit, dispatch, getters: { getCurrentUserAutoOffline: true } },
        { autoOffline: false, accountId: 1 }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_CURRENT_USER_AUTO_OFFLINE, false],
        [types.SET_CURRENT_USER_AUTO_OFFLINE, true],
      ]);
    });
  });

  describe('#updateUISettings', () => {
    it('sends correct actions if API is success', async () => {
      axios.put.mockResolvedValue({
        data: {
          id: 1,
          name: 'John',
          availability_status: 'offline',
          ui_settings: { is_contact_sidebar_open: true },
        },
        headers: { expiry: 581842904 },
      });
      await actions.updateUISettings(
        { commit, dispatch },
        { uiSettings: { is_contact_sidebar_open: false } }
      );
      expect(commit.mock.calls).toEqual([
        [
          types.SET_CURRENT_USER_UI_SETTINGS,
          { uiSettings: { is_contact_sidebar_open: false } },
        ],
        [
          types.SET_CURRENT_USER,
          {
            id: 1,
            name: 'John',
            availability_status: 'offline',
            ui_settings: { is_contact_sidebar_open: true },
          },
        ],
      ]);
    });
  });

  describe('#setUser', () => {
    it('sends correct actions if user is logged in', async () => {
      Cookies.get.mockImplementation(() => true);
      actions.setUser({ commit, dispatch });
      expect(commit.mock.calls).toEqual([]);
      expect(dispatch.mock.calls).toEqual([['validityCheck']]);
    });

    it('sends correct actions if user is not logged in', async () => {
      Cookies.get.mockImplementation(() => false);
      actions.setUser({ commit, dispatch });
      expect(commit.mock.calls).toEqual([
        [types.CLEAR_USER],
        [types.SET_CURRENT_USER_UI_FLAGS, { isFetching: false }],
      ]);
      expect(dispatch).toHaveBeenCalledTimes(0);
    });
  });

  describe('#setCurrentUserAvailability', () => {
    it('sends correct mutations if user id is available', async () => {
      actions.setCurrentUserAvailability(
        {
          commit,
          state: { currentUser: { id: 1 } },
        },
        { 1: 'online' }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_CURRENT_USER_AVAILABILITY, 'online'],
      ]);
    });

    it('does not send correct mutations if user id is not available', async () => {
      actions.setCurrentUserAvailability(
        {
          commit,
          state: { currentUser: { id: 1 } },
        },
        {}
      );
      expect(commit.mock.calls).toEqual([]);
    });
  });

  describe('#setActiveAccount', () => {
    it('sends correct mutations if account id is available', async () => {
      actions.setActiveAccount(
        {
          commit,
        },
        { accountId: 1 }
      );
    });
  });
});
