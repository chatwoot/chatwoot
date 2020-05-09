import { SET_WIDGET_COLOR } from '../types';

const state = {
  widgetColor: '',
};

const getters = {
  getWidgetColor: $state => $state.widgetColor,
};

const actions = {
  setWidgetColor({ commit }, data) {
    commit(SET_WIDGET_COLOR, data);
  },
};

const mutations = {
  [SET_WIDGET_COLOR]($state, data) {
    $state.widgetColor = data.widgetColor;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
