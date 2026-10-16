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

// Counts are shared across assignee tabs, pages, and sort orders.
const getViewKey = ({
  inboxId,
  status,
  labels,
  teamId,
  conversationType,
  queryData,
}) =>
  JSON.stringify([
    ConversationApi.url,
    queryData || {
      inboxId,
      status,
      labels,
      teamId,
      conversationType,
    },
  ]);

let activeView = { key: null, params: {}, committedRequestId: 0 };
let requestId = 0;

const isCurrentRequest = request =>
  request.view === activeView && request.id >= activeView.committedRequestId;

const commitCounts = (commit, meta, request) => {
  if (!isCurrentRequest(request)) return;

  activeView.committedRequestId = request.id;
  commit(types.SET_CONV_TAB_META, meta);
};

const fetchMetaData = async (commit, params, request) => {
  if (!isCurrentRequest(request)) return;

  try {
    const response = params.queryData
      ? await ConversationApi.filter({ queryData: params.queryData, page: 1 })
      : await ConversationApi.meta(params);
    const {
      data: { meta },
    } = response;
    commitCounts(commit, meta, request);
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
  get: ({ commit, state: $state }, params = activeView.params) => {
    if (getViewKey(params) !== activeView.key) return;

    requestId += 1;
    metaDebouncers[getMetaDebounceKey($state.allCount)](commit, params, {
      view: activeView,
      id: requestId,
    });
  },
  onListRequestStarted(_, params) {
    const key = getViewKey(params);
    if (key !== activeView.key) {
      activeView = { key, params, committedRequestId: 0 };
    }
    requestId += 1;
    return { view: activeView, id: requestId };
  },
  set({ commit }, { meta, request }) {
    commitCounts(commit, meta, request);
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
