import { SET_REFERRER_HOST, SET_WIDGET_COLOR } from '../types';

const state = {
  widgetColor: '',
  referrerHost: '',
};

export const getters = {
  getWidgetColor: $state => $state.widgetColor,
  getReferrerHost: $state => $state.referrerHost,
};

export const actions = {
  setWidgetColor({ commit }, data) {
    commit(SET_WIDGET_COLOR, data);
  },
  setReferrerHost({ commit }, referrerHost) {
    commit(SET_REFERRER_HOST, referrerHost);
  },
};

export const mutations = {
  [SET_WIDGET_COLOR]($state, data) {
    $state.widgetColor = data.widgetColor;
  },
  [SET_REFERRER_HOST]($state, referrerHost) {
    $state.referrerHost = referrerHost;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
