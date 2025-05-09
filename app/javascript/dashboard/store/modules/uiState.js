const initialState = {
  isCopilotSidebarOpen: false,
  isConversationSidebarOpen: true,
};

const types = {
  SET_UI_STATE: 'SET_UI_STATE',
};

const mutations = {
  [types.SET_UI_STATE](state, { key, value }) {
    state[key] = value;
  },
};

const getters = {
  getUIState: state => key => state[key],
};

const actions = {
  toggle({ commit, state }, key) {
    commit(types.SET_UI_STATE, { key, value: !state[key] });
  },
  set({ commit }, payload) {
    Object.entries(payload).forEach(([key, value]) => {
      commit(types.SET_UI_STATE, { key, value });
    });
  },
};

export default {
  namespaced: true,
  state: initialState,
  getters,
  mutations,
  actions,
};
