import {
  SET_REFERRER_HOST,
  SET_WIDGET_APP_CONFIG,
  SET_WIDGET_COLOR,
  TOGGLE_WIDGET_OPEN,
} from '../types';

const state = {
  showPopoutButton: false,
  hideMessageBubble: false,
  position: 'right',
  isWebWidgetTriggered: false,
  isCampaignViewClicked: false,
  isWidgetOpen: false,
  widgetColor: '',
  referrerHost: '',
};

export const getters = {
  getAppConfig: $state => $state,
  isRightAligned: $state => $state.position === 'right',
  getHideMessageBubble: $state => $state.hideMessageBubble,
  getIsWidgetOpen: $state => $state.isWidgetOpen,
  getWidgetColor: $state => $state.widgetColor,
  getReferrerHost: $state => $state.referrerHost,
};

export const actions = {
  setAppConfig({ commit }, { showPopoutButton, position, hideMessageBubble }) {
    commit(SET_WIDGET_APP_CONFIG, {
      showPopoutButton: !!showPopoutButton,
      position: position || 'right',
      hideMessageBubble: !!hideMessageBubble,
    });
  },
  toggleWidgetOpen({ commit }, isWidgetOpen) {
    commit(TOGGLE_WIDGET_OPEN, isWidgetOpen);
  },
  setWidgetColor({ commit }, widgetColor) {
    commit(SET_WIDGET_COLOR, widgetColor);
  },
  setReferrerHost({ commit }, referrerHost) {
    commit(SET_REFERRER_HOST, referrerHost);
  },
};

export const mutations = {
  [SET_WIDGET_APP_CONFIG]($state, data) {
    $state.showPopoutButton = data.showPopoutButton;
    $state.position = data.position;
    $state.hideMessageBubble = data.hideMessageBubble;
  },
  [TOGGLE_WIDGET_OPEN]($state, isWidgetOpen) {
    $state.isWidgetOpen = isWidgetOpen;
  },
  [SET_WIDGET_COLOR]($state, widgetColor) {
    $state.widgetColor = widgetColor;
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
