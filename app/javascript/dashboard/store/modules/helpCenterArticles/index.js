import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  articles: {
    byId: {},
    allIds: [],
    uiFlags: {
      byId: {},
    },
    meta: {
      byId: {},
    },
  },
  uiFlags: {
    allFetched: false,
    isFetching: false,
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
