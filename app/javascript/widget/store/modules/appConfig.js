import {
  SET_REFERRER_HOST,
  SET_WIDGET_APP_CONFIG,
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
  setAppConfig(
    { commit },
    { showPopoutButton, position, hideMessageBubble, widgetColor }
  ) {
    commit(SET_WIDGET_APP_CONFIG, {
      showPopoutButton: !!showPopoutButton,
      position: position || 'right',
      hideMessageBubble: !!hideMessageBubble,
      widgetColor,
    });
  },
  toggleWidgetOpen({ commit }, isWidgetOpen) {
    commit(TOGGLE_WIDGET_OPEN, isWidgetOpen);
  },
  setReferrerHost({ commit }, referrerHost) {
    commit(SET_REFERRER_HOST, referrerHost);
  },
};

const mutations = {
  [SET_WIDGET_APP_CONFIG]($state, data) {
    $state.showPopoutButton = data.showPopoutButton;
    $state.position = data.position;
    $state.hideMessageBubble = data.hideMessageBubble;
    $state.widgetColor = data.widgetColor;
  },
  [TOGGLE_WIDGET_OPEN]($state, isWidgetOpen) {
    $state.isWidgetOpen = isWidgetOpen;
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
