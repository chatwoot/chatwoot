import types from '../mutation-types';

const initialState = {
  name: '',
  path: '',
  query: {},
  params: {},
  fullPath: '',
};

// getters
export const getters = {};

// actions
export const actions = {
  updateRoute({ commit }, route) {
    commit(types.SET_ROUTE, route);
  },
};

// mutations
export const mutations = {
  [types.SET_ROUTE](_state, route) {
    _state.name = route.name;
    _state.path = route.path;
    _state.hash = route.hash;
    _state.query = route.query;
    _state.params = route.params;
    _state.fullPath = route.fullPath;
    _state.meta = route.meta;
  },
};

export default {
  state: initialState,
  getters,
  actions,
  mutations,
};
