import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  records: {},
  meta: {
    totalCount: 0,
    currentPage: 1,
  },
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isApproving: false,
    isRejecting: false,
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
