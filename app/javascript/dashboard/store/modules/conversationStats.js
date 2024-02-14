import Vue from 'vue';
import types from '../mutation-types';
import ConversationApi from '../../api/inbox/conversation';

const state = {
  mineCount: 0,
  unAssignedCount: 0,
  allCount: 0,
  allInboxOpenCount: 0,
  myTeamsOpenCount: 0,
};

export const getters = {
  getStats: $state => $state,
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
};

export const mutations = {
  [types.SET_CONV_TAB_META](
    $state,
    {
      mine_count: mineCount,
      unassigned_count: unAssignedCount,
      all_count: allCount,
      all_inbox_open_count: allInboxOpenCount,
      my_teams_open_count: myTeamsOpenCount
    } = {}
  ) {
    Vue.set($state, 'mineCount', mineCount);
    Vue.set($state, 'allCount', allCount);
    Vue.set($state, 'unAssignedCount', unAssignedCount);
    Vue.set($state, 'allInboxOpenCount', allInboxOpenCount);
    Vue.set($state, 'myTeamsOpenCount', myTeamsOpenCount);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
