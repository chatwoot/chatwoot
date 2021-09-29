import { SET_WIDGET_COLOR } from '../types';

const state = {
  widgetColor: '',
  widgetSettings: {
    showPopoutButton: false,
    widgetPosition: 'right',
    isChatTriggerHidden: false,
  },
};

const getters = {
  getWidgetColor: $state => $state.widgetColor,
  getWidgetSettings: $state => $state.widgetSettings,
};

const actions = {
  setWidgetColor({ commit }, data) {
    commit(SET_WIDGET_COLOR, data);
  },
  setWidgetSettings({ commit }, settings) {
    commit('widgetSettings', settings);
  },
};

const mutations = {
  [SET_WIDGET_COLOR]($state, data) {
    $state.widgetColor = data.widgetColor;
  },
  widgetSettings($state, settings) {
    $state.uiFlags = {
      ...$state.widgetSettings,
      ...settings,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
