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
    isUpdating: false,
    isMerging: false,
    isDeleting: false,
  },
  sortOrder: [],
  appliedFilters: [],
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
