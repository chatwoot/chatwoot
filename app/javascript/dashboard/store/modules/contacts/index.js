import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isUpdating: false,
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
