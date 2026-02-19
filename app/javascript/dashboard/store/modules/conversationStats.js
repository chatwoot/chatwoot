import types from '../mutation-types';
import ConversationApi from '../../api/inbox/conversation';
import { debounce } from '@chatwoot/utils';

const state = {
  mineCount: 0,
  unAssignedCount: 0,
  allCount: 0,
  helpNeededCount: 0,
  unreadCounts: {
    byInbox: {},
    byLabel: {},
    byStatus: {
      all: 0,
      mine: 0,
      unassigned: 0,
    },
    total: 0,
  },
};

export const getters = {
  getStats: $state => $state,
  getUnreadCountForInbox: $state => inboxId =>
    $state.unreadCounts.byInbox[inboxId] || 0,
  getUnreadCountForLabel: $state => labelName =>
    $state.unreadCounts.byLabel[labelName] || 0,
  getUnreadCountAll: $state => $state.unreadCounts.byStatus.all,
  getUnreadCountMine: $state => $state.unreadCounts.byStatus.mine,
  getUnreadCountUnassigned: $state => $state.unreadCounts.byStatus.unassigned,
  getTotalUnreadCount: $state => $state.unreadCounts.total,
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

const debouncedFetchMetaData = debounce(fetchMetaData, 500, false, 1500);
const longDebouncedFetchMetaData = debounce(fetchMetaData, 5000, false, 10000);
const superLongDebouncedFetchMetaData = debounce(
  fetchMetaData,
  10000,
  false,
  20000
);

const fetchUnreadCounts = async commit => {
  try {
    const response = await ConversationApi.getUnreadCounts();
    commit(types.SET_UNREAD_COUNTS, response.data);
  } catch (error) {
    // Silently fail - unread counts are non-critical
  }
};

const debouncedFetchUnreadCounts = debounce(fetchUnreadCounts, 1000);

export const actions = {
  get: async ({ commit, state: $state }, params) => {
    if ($state.allCount > 5000) {
      superLongDebouncedFetchMetaData(commit, params);
    } else if ($state.allCount > 100) {
      longDebouncedFetchMetaData(commit, params);
    } else {
      debouncedFetchMetaData(commit, params);
    }
  },
  set({ commit }, meta) {
    commit(types.SET_CONV_TAB_META, meta);
  },
  fetchUnreadCounts({ commit }) {
    debouncedFetchUnreadCounts(commit);
  },
};

export const mutations = {
  [types.SET_CONV_TAB_META](
    $state,
    {
      mine_count: mineCount,
      unassigned_count: unAssignedCount,
      all_count: allCount,
      help_needed_count: helpNeededCount,
    } = {}
  ) {
    $state.mineCount = mineCount;
    $state.allCount = allCount;
    $state.unAssignedCount = unAssignedCount;
    $state.helpNeededCount = helpNeededCount || 0;
    $state.updatedOn = new Date();
  },
  [types.SET_UNREAD_COUNTS]($state, payload = {}) {
    $state.unreadCounts = {
      byInbox: payload.by_inbox || {},
      byLabel: payload.by_label || {},
      byStatus: payload.by_status || { all: 0, mine: 0, unassigned: 0 },
      total: payload.total || 0,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
