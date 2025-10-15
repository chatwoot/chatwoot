import {
  SET_BUBBLE_VISIBILITY,
  SET_COLOR_SCHEME,
  SET_REFERRER_HOST,
  SET_WIDGET_APP_CONFIG,
  SET_WIDGET_COLOR,
  TOGGLE_WIDGET_OPEN,
  SET_ROUTE_UPDATE_STATE,
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
  isUpdatingRoute: false,
  welcomeTitle: '',
  welcomeDescription: '',
  availableMessage: '',
  unavailableMessage: '',
  enableFileUpload: true,
  enableEmojiPicker: true,
  enableEndConversation: true,
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
  getIsUpdatingRoute: _state => _state.isUpdatingRoute,
  getWelcomeHeading: $state => $state.welcomeTitle,
  getWelcomeTagline: $state => $state.welcomeDescription,
  getAvailableMessage: $state => $state.availableMessage,
  getUnavailableMessage: $state => $state.unavailableMessage,
  getShouldShowFilePicker: $state => $state.enableFileUpload,
  getShouldShowEmojiPicker: $state => $state.enableEmojiPicker,
  getCanUserEndConversation: $state => $state.enableEndConversation,
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
      welcomeTitle = '',
      welcomeDescription = '',
      availableMessage = '',
      unavailableMessage = '',
      enableFileUpload = true,
      enableEmojiPicker = true,
      enableEndConversation = true,
    }
  ) {
    commit(SET_WIDGET_APP_CONFIG, {
      hideMessageBubble: !!hideMessageBubble,
      position: position || 'right',
      showPopoutButton: !!showPopoutButton,
      showUnreadMessagesDialog: !!showUnreadMessagesDialog,
      widgetStyle,
      darkMode,
      welcomeTitle,
      welcomeDescription,
      availableMessage,
      unavailableMessage,
      enableFileUpload,
      enableEmojiPicker,
      enableEndConversation,
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
  setRouteTransitionState: async ({ commit }, status) => {
    // Handles the routing state during navigation to different screen
    // Called before the navigation starts and after navigation completes
    // Handling this state in app/javascript/widget/router.js
    // See issue: https://github.com/chatwoot/chatwoot/issues/10736
    commit(SET_ROUTE_UPDATE_STATE, status);
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
    $state.welcomeTitle = data.welcomeTitle;
    $state.welcomeDescription = data.welcomeDescription;
    $state.availableMessage = data.availableMessage;
    $state.unavailableMessage = data.unavailableMessage;
    $state.enableFileUpload = data.enableFileUpload;
    $state.enableEmojiPicker = data.enableEmojiPicker;
    $state.enableEndConversation = data.enableEndConversation;
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
  [SET_ROUTE_UPDATE_STATE]($state, status) {
    $state.isUpdatingRoute = status;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
