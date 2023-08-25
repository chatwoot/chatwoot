import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

export const state = {
  uiFlags: {
    allFetched: false,
    isFetching: false,
    isCreating: false,
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
