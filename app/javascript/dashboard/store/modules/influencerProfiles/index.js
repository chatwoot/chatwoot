import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const defaultColumnState = () => ({
  records: [],
  meta: { count: 0, currentPage: 1, hasMore: false },
  loading: false,
});

const state = {
  meta: {
    count: 0,
    currentPage: 1,
    hasMore: false,
    perStatusCounts: {},
  },
  records: {},
  sortOrder: [],
  kanban: {
    discovered: defaultColumnState(),
    enriched: defaultColumnState(),
    accepted: defaultColumnState(),
    rejected: defaultColumnState(),
  },
  searchResults: [],
  searchMeta: {
    total: 0,
    currentPage: 1,
    perPage: 0,
    totalPages: 0,
    loadedCount: 0,
    imported: 0,
    cached: false,
    hasSearched: false,
    creditsLeft: null,
  },
  lastSearchParams: null,
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isSearching: false,
    isImporting: false,
    isApproving: false,
    isRejecting: false,
    isAdding: false,
    isDeleting: false,
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
