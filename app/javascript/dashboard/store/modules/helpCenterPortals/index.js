import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

export const defaultPortalFlags = {
  isFetching: false,
  isUpdating: false,
  isDeleting: false,
};

const state = {
  meta: {
    allArticlesCount: 0,
    mineArticlesCount: 0,
    draftArticlesCount: 0,
    archivedArticlesCount: 0,
  },

  portals: {
    byId: {},
    allIds: [],
    uiFlags: {
      byId: {
        // 1: { isFetching: false, isUpdating: false, isDeleting: false },
      },
    },
    meta: {
      byId: {},
    },
  },
  uiFlags: {
    allFetched: false,
    isFetching: false,
    isSwitching: false,
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
