import types from '../mutation-types';
import ConversationApi from '../../api/inbox/conversation';

const state = {
  mineCount: 0,
  unAssignedCount: 0,
  allCount: 0,
  updatedOn: null,
};

export const getters = {
  getStats: $state => $state,
};

export const actions = {
  get: async ({ commit, state: $state }, params) => {
    const currentTime = new Date();
    const lastUpdatedTime = new Date($state.updatedOn);

    // Skip large accounts from making too many requests
    if (currentTime - lastUpdatedTime < 10000 && $state.allCount > 1000) {
      // eslint-disable-next-line no-console
      console.warn('Skipping conversation meta fetch');
      return;
    }

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
    } = {}
  ) {
    $state.mineCount = mineCount;
    $state.allCount = allCount;
    $state.unAssignedCount = unAssignedCount;
    $state.updatedOn = new Date();
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
