import types from '../mutation-types';
import ConversationApi from '../../api/inbox/conversation';
import { debounce } from '@chatwoot/utils';

const state = {
  mineCount: 0,
  unAssignedCount: 0,
  allCount: 0,
  commentsCount: 0,
  updatedOn: null,
};

export const getters = {
  getStats: (state) => state,
};

// Internal helper for fetching metadata from API
const fetchMetaData = async (commit, params) => {
  try {
    const {
      data: { meta },
    } = await ConversationApi.meta(params);

    commit(types.SET_CONV_TAB_META, meta);
  } catch (error) {
    // ignore
  }
};

const debouncedFetchMetaData = debounce(fetchMetaData, 500, false, 1000);
const longDebouncedFetchMetaData = debounce(fetchMetaData, 500, false, 5000);

export const actions = {
  async get({ commit, state }, params) {
    if (state.allCount > 100) {
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
    state,
    {
      mine_count: mineCount = 0,
      unassigned_count: unAssignedCount = 0,
      all_count: allCount = 0,
      comments_count: commentsCount = 0,
    } = {}
  ) {
    state.mineCount = mineCount;
    state.allCount = allCount;
    state.unAssignedCount = unAssignedCount;
    state.commentsCount = commentsCount;
    state.updatedOn = new Date();
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};



