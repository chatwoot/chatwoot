import types from '../../mutation-types';
import NotificationsAPI from '../../../api/notifications';

export const actions = {
  get: async ({ commit }, { page = 1 } = {}) => {
    commit(types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: true });
    try {
      const data = await NotificationsAPI.get(page);
      const { payload, meta } = data.data.data;
      commit(types.CLEAR_NOTIFICATIONS);

      commit(types.SET_NOTIFICATIONS, payload);
      commit(types.SET_NOTIFICATIONS_META, meta);
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: false });
    } catch (error) {
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isFetching: false });
    }
  },
  read: async (
    { commit },
    { primaryActorType, primaryActorId, unReadCount }
  ) => {
    try {
      await NotificationsAPI.read(primaryActorType, primaryActorId);
      commit(types.SET_UNREAD_COUNT, { unReadCount: unReadCount - 1 });
      commit(types.UPDATE_NOTIFICATION, primaryActorId);
    } catch (error) {
      throw new Error(error);
    }
  },
  readAll: async ({ commit }) => {
    commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: true });
    try {
      await NotificationsAPI.readAll();
      commit(types.SET_UNREAD_COUNT, { unReadCount: 0 });
      commit(types.UPDATE_ALL_NOTIFICATIONS);
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.SET_NOTIFICATIONS_UI_FLAG, { isUpdating: false });
      throw new Error(error);
    }
  },
};
