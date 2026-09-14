import types from '../mutation-types';
import ConversationApi from '../../api/inbox/conversation';
import { debounce } from '@chatwoot/utils';

const state = {
  mineCount: 0,
  unAssignedCount: 0,
  allCount: 0,
};

export const getters = {
  getStats: $state => $state,
};

// List responses supersede metadata refreshes queued for the previous view.
let listCountsVersion = 0;

const fetchMetaData = async (commit, params, version) => {
  if (version !== listCountsVersion) return;

  try {
    const response = await ConversationApi.meta(params);
    const {
      data: { meta },
    } = response;
    if (version !== listCountsVersion) return;

    commit(types.SET_CONV_TAB_META, meta);
  } catch (error) {
    // ignore
  }
};

const debouncedFetchMetaData = debounce(fetchMetaData, 1000, false, 5000);
const longDebouncedFetchMetaData = debounce(fetchMetaData, 7500, false, 20000);
const superLongDebouncedFetchMetaData = debounce(
  fetchMetaData,
  15000,
  false,
  30000
);

const metaDebouncers = {
  default: debouncedFetchMetaData,
  long: longDebouncedFetchMetaData,
  superLong: superLongDebouncedFetchMetaData,
};

// allCount is 0 until a meta request succeeds; under load it stays 0, so treat
// the unknown case as a large account and poll slowest instead of fastest.
export const getMetaDebounceKey = allCount => {
  if (allCount > 2000 || allCount === 0) return 'superLong';
  if (allCount > 100) return 'long';
  return 'default';
};

export const actions = {
  get: ({ commit, state: $state }, params) => {
    metaDebouncers[getMetaDebounceKey($state.allCount)](
      commit,
      params,
      listCountsVersion
    );
  },
  set({ commit }, meta) {
    listCountsVersion += 1;
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
