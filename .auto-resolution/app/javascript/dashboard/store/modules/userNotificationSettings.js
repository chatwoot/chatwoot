import * as types from '../mutation-types';
import UserNotificationSettings from '../../api/userNotificationSettings';

const state = {
  record: {},
  uiFlags: {
    isFetching: false,
    isUpdating: false,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getSelectedEmailFlags: $state => {
    return $state.record.selected_email_flags;
  },
  getSelectedPushFlags: $state => {
    return $state.record.selected_push_flags;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.default.SET_USER_NOTIFICATION_UI_FLAG, { isFetching: true });
    try {
      const response = await UserNotificationSettings.get();
      commit(types.default.SET_USER_NOTIFICATION, response.data);
      commit(types.default.SET_USER_NOTIFICATION_UI_FLAG, {
        isFetching: false,
      });
    } catch (error) {
      commit(types.default.SET_USER_NOTIFICATION_UI_FLAG, {
        isFetching: false,
      });
    }
  },

  update: async ({ commit }, { selectedEmailFlags, selectedPushFlags }) => {
    commit(types.default.SET_USER_NOTIFICATION_UI_FLAG, { isUpdating: true });
    try {
      const response = await UserNotificationSettings.update({
        notification_settings: {
          selected_email_flags: selectedEmailFlags,
          selected_push_flags: selectedPushFlags,
        },
      });
      commit(types.default.SET_USER_NOTIFICATION, response.data);
      commit(types.default.SET_USER_NOTIFICATION_UI_FLAG, {
        isUpdating: false,
      });
    } catch (error) {
      commit(types.default.SET_USER_NOTIFICATION_UI_FLAG, {
        isUpdating: false,
      });
      throw error;
    }
  },
};

export const mutations = {
  [types.default.SET_USER_NOTIFICATION_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_USER_NOTIFICATION]: ($state, data) => {
    $state.record = data;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
