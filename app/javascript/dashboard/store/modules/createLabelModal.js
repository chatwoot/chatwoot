import * as types from '../mutation-types';

const state = {
  showCreateLabelModal: false,
  preFillTitle: '',
};

export const getters = {
  getShowCreateLabelModal($state) {
    return $state.showCreateLabelModal;
  },
  getPreFillTitle: $state => {
    return $state.preFillTitle;
  },
};

export const actions = {
  toggleShowCreateLabelModal: async ({ commit }, { value, title }) => {
    commit(types.default.SET_SHOW_CREATE_LABEL_MODAL, value);
    commit(types.default.SET_PREFILL_TITLE, title);
  },
  closeShowCreateLabelModal: async ({ commit }) => {
    commit(types.default.SET_SHOW_CREATE_LABEL_MODAL, false);
  },
};

export const mutations = {
  [types.default.SET_SHOW_CREATE_LABEL_MODAL]($state, data) {
    $state.showCreateLabelModal = data;
  },
  [types.default.SET_PREFILL_TITLE]: ($state, data) => {
    $state.preFillTitle = data;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
