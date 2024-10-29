import {
  SET_BUBBLE_VISIBILITY,
  SET_COLOR_SCHEME,
  SET_REFERRER_HOST,
  SET_WIDGET_APP_CONFIG,
  SET_WIDGET_COLOR,
  TOGGLE_WIDGET_OPEN,
} from '../types';

const state = {
  hideMessageBubble: false,
  isCampaignViewClicked: false,
  showUnreadMessagesDialog: true,
  isWebWidgetTriggered: false,
  isWidgetOpen: false,
  position: 'right',
  referrerHost: '',
  showPopoutButton: false,
  widgetColor: '',
  widgetStyle: 'standard',
  darkMode: 'light',
};

export const getters = {
  getAppConfig: $state => $state,
  isRightAligned: $state => $state.position === 'right',
  getHideMessageBubble: $state => $state.hideMessageBubble,
  getIsWidgetOpen: $state => $state.isWidgetOpen,
  getWidgetColor: $state => $state.widgetColor,
  getReferrerHost: $state => $state.referrerHost,
  isWidgetStyleFlat: $state => $state.widgetStyle === 'flat',
  darkMode: $state => $state.darkMode,
  getShowUnreadMessagesDialog: $state => $state.showUnreadMessagesDialog,
};

export const actions = {
  setAppConfig(
    { commit },
    {
      showPopoutButton,
      position,
      hideMessageBubble,
      showUnreadMessagesDialog,
      widgetStyle = 'rounded',
      darkMode = 'light',
    }
  ) {
    commit(SET_WIDGET_APP_CONFIG, {
      hideMessageBubble: !!hideMessageBubble,
      position: position || 'right',
      showPopoutButton: !!showPopoutButton,
      showUnreadMessagesDialog: !!showUnreadMessagesDialog,
      widgetStyle,
      darkMode,
    });
  },
  toggleWidgetOpen({ commit }, isWidgetOpen) {
    commit(TOGGLE_WIDGET_OPEN, isWidgetOpen);
  },
  setWidgetColor({ commit }, widgetColor) {
    commit(SET_WIDGET_COLOR, widgetColor);
  },
  setColorScheme({ commit }, darkMode) {
    commit(SET_COLOR_SCHEME, darkMode);
  },
  setReferrerHost({ commit }, referrerHost) {
    commit(SET_REFERRER_HOST, referrerHost);
  },
  setBubbleVisibility({ commit }, hideMessageBubble) {
    commit(SET_BUBBLE_VISIBILITY, hideMessageBubble);
  },
};

export const mutations = {
  [SET_WIDGET_APP_CONFIG]($state, data) {
    $state.showPopoutButton = data.showPopoutButton;
    $state.position = data.position;
    $state.hideMessageBubble = data.hideMessageBubble;
    $state.widgetStyle = data.widgetStyle;
    $state.darkMode = data.darkMode;
    $state.locale = data.locale || $state.locale;
    $state.showUnreadMessagesDialog = data.showUnreadMessagesDialog;
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
  [SET_BUBBLE_VISIBILITY]($state, hideMessageBubble) {
    $state.hideMessageBubble = hideMessageBubble;
  },
  [SET_COLOR_SCHEME]($state, darkMode) {
    $state.darkMode = darkMode;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
