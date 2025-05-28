import types from '../../mutation-types';
import NotificationsAPI from '../../../api/notifications';

export const actions = {
  get: async ({ commit }, { page = 1 } = {}) => {
    commit(types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: true });
    try {
      const {
        data: {
          data: { payload, meta },
        },
      } = await NotificationsAPI.get({ page });
      commit(types.CLEAR_NOTIFICATIONS);
      commit(types.SET_NOTIFICATIONS, payload);
      commit(types.SET_NOTIFICATIONS_META, meta);
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: false });
    }
  },
  index: async ({ commit }, { page = 1, status, type, sortOrder } = {}) => {
    commit(types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: true });
    try {
      const {
        data: {
          data: { payload, meta },
        },
      } = await NotificationsAPI.get({
        page,
        status,
        type,
        sortOrder,
      });
      commit(types.SET_NOTIFICATIONS, payload);
      commit(types.SET_NOTIFICATIONS_META, meta);
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: false });
      if (payload.length < 15) {
        commit(types.SET_ALL_NOTIFICATIONS_LOADED);
      }
    } catch (error) {
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: false });
    }
  },
  unReadCount: async ({ commit } = {}) => {
    commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdatingUnreadCount: true });
    try {
      const { data } = await NotificationsAPI.getUnreadCount();
      commit(types.SET_NOTIFICATIONS_UNREAD_COUNT, data);
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdatingUnreadCount: false });
    } catch (error) {
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdatingUnreadCount: false });
    }
  },
  read: async (
    { commit },
    { id, primaryActorType, primaryActorId, unreadCount }
  ) => {
    commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: true });
    try {
      await NotificationsAPI.read(primaryActorType, primaryActorId);
      commit(types.SET_NOTIFICATIONS_UNREAD_COUNT, unreadCount - 1);
      commit(types.READ_NOTIFICATION, { id, read_at: new Date() });
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false });
    }
  },
  unread: async ({ commit }, { id }) => {
    commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: true });
    try {
      await NotificationsAPI.unRead(id);
      commit(types.READ_NOTIFICATION, { id, read_at: null });
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false });
    }
  },
  readAll: async ({ commit }) => {
    commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: true });
    try {
      await NotificationsAPI.readAll();
      commit(types.SET_NOTIFICATIONS_UNREAD_COUNT, 0);
      commit(types.UPDATE_ALL_NOTIFICATIONS);
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false });
      throw new Error(error);
    }
  },

  delete: async ({ commit }, { notification, count, unreadCount }) => {
    commit(types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: true });
    try {
      await NotificationsAPI.delete(notification.id);
      commit(types.SET_NOTIFICATIONS_UNREAD_COUNT, unreadCount - 1);
      commit(types.DELETE_NOTIFICATION, { notification, count, unreadCount });
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: false });
    } catch (error) {
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: false });
    }
  },

  deleteAllRead: async ({ commit }) => {
    commit(types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: true });
    try {
      await NotificationsAPI.deleteAll({
        type: 'read',
      });
      commit(types.DELETE_READ_NOTIFICATIONS);
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: false });
    } catch (error) {
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: false });
    }
  },
  deleteAll: async ({ commit }) => {
    commit(types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: true });
    try {
      await NotificationsAPI.deleteAll({
        type: 'all',
      });
      commit(types.DELETE_ALL_NOTIFICATIONS);
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: false });
    } catch (error) {
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isDeleting: false });
    }
  },

  snooze: async ({ commit }, { id, snoozedUntil }) => {
    commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: true });
    try {
      const response = await NotificationsAPI.snooze({
        id,
        snoozedUntil,
      });

      const {
        data: { snoozed_until = null },
      } = response;
      commit(types.SNOOZE_NOTIFICATION, {
        id,
        snoozed_until,
      });
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false });
    }
  },

  updateNotification: async ({ commit }, data) => {
    commit(types.UPDATE_NOTIFICATION, data);
  },

  addNotification({ commit }, data) {
    commit(types.ADD_NOTIFICATION, data);
  },
  deleteNotification({ commit }, data) {
    commit(types.DELETE_NOTIFICATION, data);
  },
  clear({ commit }) {
    commit(types.CLEAR_NOTIFICATIONS);
  },

  setNotificationFilters: ({ commit }, filters) => {
    commit(types.SET_NOTIFICATION_FILTERS, filters);
  },
  updateNotificationFilters: ({ commit }, filters) => {
    commit(types.UPDATE_NOTIFICATION_FILTERS, filters);
  },
};
