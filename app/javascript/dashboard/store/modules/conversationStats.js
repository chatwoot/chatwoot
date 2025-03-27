import types from '../mutation-types';
import ConversationApi from '../../api/inbox/conversation';

import ConversationMetaThrottleManager from 'dashboard/helper/ConversationMetaThrottleManager';

const state = {
  mineCount: 0,
  unAssignedCount: 0,
  allCount: 0,
};

export const getters = {
  getStats: $state => $state,
};

export const shouldThrottle = conversationCount => {
  // The threshold for throttling is different for normal users and large accounts
  // Normal users: 2 seconds
  // Large accounts: 10 seconds
  // We would only update the conversation stats based on the threshold above.
  // This is done to reduce the number of /meta request made to the server.
  const NORMAL_USER_THRESHOLD = 2000;
  const LARGE_ACCOUNT_THRESHOLD = 10000;

  const threshold =
    conversationCount > 100 ? LARGE_ACCOUNT_THRESHOLD : NORMAL_USER_THRESHOLD;
  return ConversationMetaThrottleManager.shouldThrottle(threshold);
};

export const actions = {
  get: async ({ commit, state: $state }, params) => {
    if (shouldThrottle($state.allCount)) {
      // eslint-disable-next-line no-console
      console.warn('Throttle /meta fetch, will resume after threshold');
      return;
    }
    ConversationMetaThrottleManager.markUpdate();

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
