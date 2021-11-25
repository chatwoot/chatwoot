import axios from 'axios';
import Cookies from 'js-cookie';
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
jest.mock('js-cookie', () => ({
  getJSON: jest.fn(),
}));

const commit = jest.fn();
const dispatch = jest.fn();
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

  describe('#updateProfile', () => {
    it('sends correct actions if API is success', async () => {
      axios.put.mockResolvedValue({
        data: { id: 1, name: 'John' },
        headers: { expiry: 581842904 },
      });
      await actions.updateProfile({ commit }, { name: 'Pranav' });
      expect(setUser).toHaveBeenCalledTimes(1);
      expect(commit.mock.calls).toEqual([[types.default.SET_CURRENT_USER]]);
    });
  });

  describe('#updateAvailability', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({
        data: {
          id: 1,
          account_users: [{ account_id: 1, availability_status: 'offline' }],
        },
        headers: { expiry: 581842904 },
      });
      await actions.updateAvailability(
        { commit, dispatch },
        { availability: 'offline', account_id: 1 },
      );
      expect(setUser).toHaveBeenCalledTimes(1);
      expect(commit.mock.calls).toEqual([[types.default.SET_CURRENT_USER]]);
      expect(dispatch.mock.calls).toEqual([
        ['agents/updatePresence', { 1: 'offline' }],
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
      expect(setUser).toHaveBeenCalledTimes(1);
      expect(commit.mock.calls).toEqual([
        [
          types.default.SET_CURRENT_USER_UI_SETTINGS,
          { uiSettings: { is_contact_sidebar_open: false } },
        ],
        [types.default.SET_CURRENT_USER],
      ]);
    });
  });

  describe('#setUser', () => {
    it('sends correct actions if user is logged in', async () => {
      Cookies.getJSON.mockImplementation(() => true);
      actions.setUser({ commit, dispatch });
      expect(commit.mock.calls).toEqual([[types.default.SET_CURRENT_USER]]);
      expect(dispatch.mock.calls).toEqual([['validityCheck']]);
    });

    it('sends correct actions if user is not logged in', async () => {
      Cookies.getJSON.mockImplementation(() => false);
      actions.setUser({ commit, dispatch });
      expect(commit.mock.calls).toEqual([[types.default.CLEAR_USER]]);
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
        [types.default.SET_CURRENT_USER_AVAILABILITY, 'online'],
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
});
