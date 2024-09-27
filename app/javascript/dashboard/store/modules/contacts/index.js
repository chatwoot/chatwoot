import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  meta: {
    count: 0,
    currentPage: 1,
  },
  records: {},
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isFetchingInboxes: false,
    isFetchingTransactions: false,
    isFetchingConversationPlans: false,
    isUpdating: false,
    isMerging: false,
    isDeleting: false,
  },
  sortOrder: [],
  appliedFilters: [],
  stageMeta: {},
  availableProducts: [],
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
