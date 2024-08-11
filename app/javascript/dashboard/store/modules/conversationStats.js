import Vue from 'vue';
import types from '../mutation-types';
import ConversationApi from '../../api/inbox/conversation';

const state = {
  unreadMeta: {},
  isUnreadLoaded: {},
  meta: {
    mineCount: 0,
    unAssignedCount: 0,
    allCount: 0,
  },
};

export const getters = {
  getStats: $state => $state.meta,

  getUnreadStats: $state => $state.unreadMeta,

  getUnreadStatsByKey: $state => key => {
    const itemStats = $state.unreadMeta[key];
    return itemStats || {};
  },

  getUnreadLoadedByKey: $state => key => {
    return $state.isUnreadLoaded[key] || false;
  },
};

export const actions = {
  get: async ({ commit }, params) => {
    try {
      const response = await ConversationApi.meta(params);
      const {
        data: { meta },
      } = response;
      commit(types.SET_CONV_TAB_META, meta);
    } catch (error) {
      // Ignore error
    }
  },
  set({ commit }, meta) {
    commit(types.SET_CONV_TAB_META, meta);
  },
  getUnread: async ({ commit }, { key, params }) => {
    try {
      const response = await ConversationApi.meta(params, true);
      const {
        data: { meta },
      } = response;
      commit(types.SET_CONV_UNREAD_LOADED, key);
      commit(types.SET_CONV_UNREAD_META, { key, meta });
    } catch (error) {
      // Ignore error
    }
  },
};

export const mutations = {
  [types.SET_CONV_TAB_META](
    $state,
    {
      mine_count: mineCount,
      unassigned_count: unAssignedCount,
      all_count: allCount,
    } = {}
  ) {
    Vue.set($state.meta, 'mineCount', mineCount);
    Vue.set($state.meta, 'allCount', allCount);
    Vue.set($state.meta, 'unAssignedCount', unAssignedCount);
  },

  [types.SET_CONV_UNREAD_META]: ($state, { key, meta }) => {
    Vue.set($state.unreadMeta, key, {
      ...($state.unreadMeta[key] || {}),
      ...meta,
    });
  },

  [types.SET_CONV_UNREAD_LOADED]: ($state, key) => {
    Vue.set($state.isUnreadLoaded, key, true);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
