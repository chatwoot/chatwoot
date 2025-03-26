import types from '../mutation-types';
import { debounce } from '@chatwoot/utils';
import ConversationApi from '../../api/inbox/conversation';

const state = {
  mineCount: 0,
  unAssignedCount: 0,
  allCount: 0,
};

export const getters = {
  getStats: $state => $state,
};

// Create a debounced version of the actual API call function
const fetchMetaData = async (commit, params) => {
  try {
    const response = await ConversationApi.meta(params);
    const {
      data: { meta },
    } = response;
    commit(types.SET_CONV_TAB_META, meta);
  } catch (error) {
    // ignore
  }
};

const debouncedFetchMetaData = debounce(fetchMetaData, 500);
const longDebouncedFetchMetaData = debounce(fetchMetaData, 5000);

export const actions = {
  get: ({ commit, state: $state }, params) => {
    if ($state.allCount > 100) {
      longDebouncedFetchMetaData(commit, params);
    } else {
      debouncedFetchMetaData(commit, params);
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
