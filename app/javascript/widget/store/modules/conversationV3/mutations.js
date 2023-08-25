import Vue from 'vue';
import { state as defaultState } from './index';

export const mutations = {
  setUIFlag($state, uiFlags) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...uiFlags,
    };
  },

  setConversationUIFlag($state, { conversationId, uiFlags }) {
    const defaultFlags = {
      allFetched: false,
      isAgentTyping: false,
      isFetching: false,
    };
    const flags = $state.conversations.uiFlags.byId[conversationId];
    Vue.set($state.conversations.uiFlags.byId, conversationId, {
      ...defaultFlags,
      ...flags,
      ...uiFlags,
    });
  },

  clearConversations($state) {
    Vue.set($state, 'conversations', defaultState.conversations);
    Vue.set($state, 'uiFlags', defaultState.uiFlags);
  },
};
