import axios from 'axios';
import { actions } from '../../notifications/actions';
import types from '../../../mutation-types';

const commit = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: {
          data: {
            payload: [{ id: 1 }],
            meta: { count: 3, current_page: 1, unread_count: 2 },
          },
        },
      });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: true }],
        [types.CLEAR_NOTIFICATIONS],
        [types.SET_NOTIFICATIONS, [{ id: 1 }]],
        [
          types.SET_NOTIFICATIONS_META,
          { count: 3, current_page: 1, unread_count: 2 },
        ],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: true }],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: false }],
      ]);
    });
  });

  describe('#unReadCount', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: 1 });
      await actions.unReadCount({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdatingUnreadCount: true }],
        [types.SET_NOTIFICATIONS_UNREAD_COUNT, 1],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdatingUnreadCount: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.unReadCount({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdatingUnreadCount: true }],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdatingUnreadCount: false }],
      ]);
    });
  });

  describe('#read', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({});
      await actions.read({ commit }, { unreadCount: 2, primaryActorId: 1 });
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UNREAD_COUNT, 1],
        [types.UPDATE_NOTIFICATION, 1],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.read({ commit })).rejects.toThrow(Error);
    });
  });

  describe('#readAll', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: 1 });
      await actions.readAll({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: true }],
        [types.SET_NOTIFICATIONS_UNREAD_COUNT, 0],
        [types.UPDATE_ALL_NOTIFICATIONS],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.readAll({ commit })).rejects.toThrow(Error);
    });
  });
  describe('#addNotification', () => {
    it('sends correct actions if API is success', async () => {
      await actions.addNotification({ commit }, { data: 1 });
      expect(commit.mock.calls).toEqual([
        [types.ADD_NOTIFICATION, { data: 1 }],
      ]);
    });
  });
});
