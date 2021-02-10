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
      } = await NotificationsAPI.get(page);
      commit(types.CLEAR_NOTIFICATIONS);
      commit(types.SET_NOTIFICATIONS, payload);
      commit(types.SET_NOTIFICATIONS_META, meta);
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: false });
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
    { primaryActorType, primaryActorId, unreadCount }
  ) => {
    try {
      await NotificationsAPI.read(primaryActorType, primaryActorId);
      commit(types.SET_NOTIFICATIONS_UNREAD_COUNT, unreadCount - 1);
      commit(types.UPDATE_NOTIFICATION, primaryActorId);
    } catch (error) {
      throw new Error(error);
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
};
