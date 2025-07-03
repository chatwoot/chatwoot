import axios from 'axios';
import { actions } from '../../notifications/actions';
import types from '../../../mutation-types';
const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

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

  describe('#index', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({
        data: {
          data: {
            payload: [{ id: 1 }],
            meta: { count: 3, current_page: 1, unread_count: 2 },
          },
        },
      });
      await actions.index({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: true }],
        [types.SET_NOTIFICATIONS, [{ id: 1 }]],
        [
          types.SET_NOTIFICATIONS_META,
          { count: 3, current_page: 1, unread_count: 2 },
        ],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: false }],
        [types.SET_ALL_NOTIFICATIONS_LOADED],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.index({ commit });
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
      await actions.read(
        { commit },
        { id: 1, unreadCount: 2, primaryActorId: 1 }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: true }],
        [types.SET_NOTIFICATIONS_UNREAD_COUNT, 1],
        [types.READ_NOTIFICATION, { id: 1, read_at: expect.any(Date) }],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.read({ commit })).rejects.toThrow(Error);
      await actions.read(
        { commit },
        { id: 1, unreadCount: 2, primaryActorId: 1 }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: true }],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#unread', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({});
      await actions.unread({ commit }, { id: 1 });
      expect(commit.mock.calls).toEqual([
        ['SET_NOTIFICATIONS_UI_FLAG', { isUpdating: true }],
        ['READ_NOTIFICATION', { id: 1, read_at: null }],
        ['SET_NOTIFICATIONS_UI_FLAG', { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.unread({ commit })).rejects.toThrow(Error);
      await actions.unread({ commit }, { id: 1 });
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: true }],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('#delete', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({});
      await actions.delete(
        { commit },
        {
          notification: { id: 1 },
          count: 2,
          unreadCount: 1,
        }
      );

      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: true }],
        [types.SET_NOTIFICATIONS_UNREAD_COUNT, 0],
        [
          types.DELETE_NOTIFICATION,
          { notification: { id: 1 }, count: 2, unreadCount: 1 },
        ],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await expect(actions.delete({ commit })).rejects.toThrow(Error);
      await actions.delete(
        { commit },
        {
          notification: { id: 1 },
          count: 2,
          unreadCount: 1,
        }
      );
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: true }],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: false }],
      ]);
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

  describe('#deleteNotification', () => {
    it('sends correct actions', async () => {
      await actions.deleteNotification({ commit }, { data: 1 });
      expect(commit.mock.calls).toEqual([
        [types.DELETE_NOTIFICATION, { data: 1 }],
      ]);
    });
  });

  describe('clear', () => {
    it('sends correct actions', async () => {
      await actions.clear({ commit });
      expect(commit.mock.calls).toEqual([[types.CLEAR_NOTIFICATIONS]]);
    });
  });

  describe('deleteAllRead', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({});
      await actions.deleteAllRead({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: true }],
        [types.DELETE_READ_NOTIFICATIONS],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await actions.deleteAllRead({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: true }],
        [types.DELETE_READ_NOTIFICATIONS],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });

  describe('deleteAll', () => {
    it('sends correct actions if API is success', async () => {
      axios.delete.mockResolvedValue({});
      await actions.deleteAll({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: true }],
        [types.DELETE_ALL_NOTIFICATIONS],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.delete.mockRejectedValue({ message: 'Incorrect header' });
      await actions.deleteAll({ commit });
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: true }],
        [types.DELETE_ALL_NOTIFICATIONS],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: false }],
      ]);
    });
  });

  describe('snooze', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({
        data: { snoozed_until: '20 Jan, 5.04pm' },
      });
      await actions.snooze({ commit }, { id: 1, snoozedUntil: 1703057715 });
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: true }],
        [types.SNOOZE_NOTIFICATION, { id: 1, snoozed_until: '20 Jan, 5.04pm' }],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false }],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await actions.snooze({ commit }, { id: 1, snoozedUntil: 1703057715 });

      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: true }],
        [types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false }],
      ]);
    });
  });

  describe('setNotificationFilters', () => {
    it('set notification filters', async () => {
      const filters = {
        page: 1,
        status: 'read',
        type: 'all',
        sortOrder: 'desc',
      };
      await actions.setNotificationFilters({ commit }, filters);
      expect(commit.mock.calls).toEqual([
        [types.SET_NOTIFICATION_FILTERS, filters],
      ]);
    });
  });

  describe('updateNotificationFilters', () => {
    it('update notification filters', async () => {
      const filters = {
        page: 1,
        status: 'unread',
        type: 'all',
        sortOrder: 'desc',
      };
      await actions.updateNotificationFilters({ commit }, filters);
      expect(commit.mock.calls).toEqual([
        [types.UPDATE_NOTIFICATION_FILTERS, filters],
      ]);
    });
  });
});
