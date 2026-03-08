import types from '../mutation-types';

export const state = {
  selectedMessageIds: [],
  uiFlags: {
    isUpdating: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getSelectedMessageIds(_state) {
    return _state.selectedMessageIds;
  },
  isMessageSelected: _state => id => {
    return _state.selectedMessageIds.includes(id);
  },
  hasSelectedMessages(_state) {
    return _state.selectedMessageIds.length > 0;
  },
};

export const actions = {
  setSelectedMessageIds({ commit }, id) {
    commit(types.SET_SELECTED_MESSAGE_IDS, id);
  },
  removeSelectedMessageIds({ commit }, id) {
    commit(types.REMOVE_SELECTED_MESSAGE_IDS, id);
  },
  clearSelectedMessageIds({ commit }) {
    commit(types.CLEAR_SELECTED_MESSAGE_IDS);
  },
  toggleMessageSelection({ commit, getters: storeGetters }, id) {
    if (storeGetters.isMessageSelected(id)) {
      commit(types.REMOVE_SELECTED_MESSAGE_IDS, id);
    } else {
      commit(types.SET_SELECTED_MESSAGE_IDS, id);
    }
  },
};

export const mutations = {
  [types.SET_SELECTED_MESSAGE_IDS](_state, ids) {
    const idsArray = Array.isArray(ids) ? ids : [ids];
    _state.selectedMessageIds = [
      ...new Set([..._state.selectedMessageIds, ...idsArray]),
    ];
  },
  [types.REMOVE_SELECTED_MESSAGE_IDS](_state, id) {
    _state.selectedMessageIds = _state.selectedMessageIds.filter(
      item => item !== id
    );
  },
  [types.CLEAR_SELECTED_MESSAGE_IDS](_state) {
    _state.selectedMessageIds = [];
  },
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
