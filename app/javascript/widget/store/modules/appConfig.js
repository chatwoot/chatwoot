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
  // True only when the widget was opened by a real user click on the bubble
  // (not by `window.$chatwoot.toggle('open')`). Resets when the widget is closed.
  // See #14022.
  isWidgetOpenedByUser: false,
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
  enableFileUpload: undefined,
  enableEmojiPicker: true,
  enableEndConversation: true,
};

export const getters = {
  getAppConfig: $state => $state,
  isRightAligned: $state => $state.position === 'right',
  getHideMessageBubble: $state => $state.hideMessageBubble,
  getIsWidgetOpen: $state => $state.isWidgetOpen,
  getIsWidgetOpenedByUser: $state => $state.isWidgetOpenedByUser,
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
      enableFileUpload = undefined,
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
  // Accepts either the legacy boolean form (`isWidgetOpen`) or an object
  // `{ isWidgetOpen, isUserInitiated }`. The object form is used when the
  // widget is opened programmatically via `window.$chatwoot.toggle('open')`,
  // so we can distinguish "user is actively chatting" from "widget was
  // pre-opened by an integrator script". See #14022.
  toggleWidgetOpen({ commit }, payload) {
    const isObjectPayload = typeof payload === 'object' && payload !== null;
    const isWidgetOpen = isObjectPayload ? payload.isWidgetOpen : payload;
    const isUserInitiated = isObjectPayload
      ? Boolean(payload.isUserInitiated)
      : false;
    commit(TOGGLE_WIDGET_OPEN, { isWidgetOpen, isUserInitiated });
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
  [TOGGLE_WIDGET_OPEN]($state, { isWidgetOpen, isUserInitiated }) {
    $state.isWidgetOpen = isWidgetOpen;
    if (!isWidgetOpen) {
      // Any close clears the "opened by user" flag so the next open is
      // evaluated fresh.
      $state.isWidgetOpenedByUser = false;
    } else if (isUserInitiated) {
      $state.isWidgetOpenedByUser = true;
    }
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
