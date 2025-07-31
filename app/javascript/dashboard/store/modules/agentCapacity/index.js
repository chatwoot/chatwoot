import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  policies: {},
  agentCapacities: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isAssigningAgents: false,
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
