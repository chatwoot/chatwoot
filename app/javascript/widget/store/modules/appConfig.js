import {
  SET_REFERRER_HOST,
  SET_WIDGET_APP_CONFIG,
  SET_WIDGET_COLOR,
  TOGGLE_WIDGET_OPEN,
} from '../types';

const state = {
  widgetColor: '',
  showPopoutButton: false,
  hideMessageBubble: false,
  position: 'right',
  isWebWidgetTriggered: false,
  isCampaignViewClicked: false,
  isWidgetOpen: false,
  referrerHost: '',
};

const getters = {
  getWidgetColor: $state => $state.widgetColor,
  isRightAligned: $state => $state.position === 'right',
  getHideMessageBubble: $state => $state.hideMessageBubble,
  getIsWidgetOpen: $state => $state.isWidgetOpen,
  getReferrerHost: $state => $state.referrerHost,
  getAppConfig: $state => $state,
};

const actions = {
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
  setReferrerHost({ commit }, referrerHost) {
    commit(SET_REFERRER_HOST, referrerHost);
  },
  setWidgetColor({ commit }, widgetColor) {
    commit(SET_WIDGET_COLOR, widgetColor);
  },
};

const mutations = {
  [SET_WIDGET_APP_CONFIG]($state, data) {
    $state.showPopoutButton = data.showPopoutButton;
    $state.position = data.position;
    $state.hideMessageBubble = data.hideMessageBubble;
  },
  [TOGGLE_WIDGET_OPEN]($state, isWidgetOpen) {
    $state.isWidgetOpen = isWidgetOpen;
  },
  [SET_REFERRER_HOST]($state, referrerHost) {
    $state.referrerHost = referrerHost;
  },
  [SET_WIDGET_COLOR]($state, widgetColor) {
    $state.widgetColor = widgetColor;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
