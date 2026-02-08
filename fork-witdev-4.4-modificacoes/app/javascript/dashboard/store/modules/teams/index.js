import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  meta: {},
  records: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
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
