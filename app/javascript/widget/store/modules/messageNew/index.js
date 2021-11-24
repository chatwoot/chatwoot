import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  messages: {
    byId: {},
    allIds: [],
    uiFlags: {
      byId: {
        // 1: { isCreating: false, isPending: false, isDeleting: false, isUpdating: false },
      },
    },
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
