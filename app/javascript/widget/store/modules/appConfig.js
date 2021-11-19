import { SET_WIDGET_APP_CONFIG } from '../types';

const state = {
  widgetColor: '',
  showPopoutButton: false,
  hideMessageBubble: false,
  widgetPosition: 'right',
  isWebWidgetTriggered: false,
  isCampaignViewClicked: false,
  isWidgetOpen: false,
};

const getters = {
  getWidgetColor: $state => $state.widgetColor,
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
};

const mutations = {
  [SET_WIDGET_APP_CONFIG]($state, data) {
    $state.showPopoutButton = data.showPopoutButton;
    $state.position = data.position;
    $state.hideMessageBubble = data.hideMessageBubble;
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
