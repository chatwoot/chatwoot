/* eslint-disable no-param-reassign */
import Vue from 'vue';
import { MESSAGE_STATUS, MESSAGE_TYPE } from 'widget/helpers/constants';
import getUuid from 'widget/helpers/uuid';
import { isEmptyObject } from 'widget/helpers/utils';
import { sendMessageAPI, getConversationAPI } from 'widget/api/conversation';

export const DEFAULT_CONVERSATION = 'default';
const state = {
  conversations: {},
};

const getters = {
  getConversationById: $state => (conversationId = '') => {
    const messages = $state.conversations[conversationId] || {};
    return isEmptyObject(messages) ? [] : Object.values(messages);
  },
};

const actions = {
  initConversations({ commit }, lastConversation) {
    commit('auth/setLastConversation', lastConversation, { root: true });
    commit('initInboxInConversations', lastConversation);
  },

  sendMessage({ commit }, params) {
    const { inboxId, accountId, contactId, content, conversationId } = params;
    const id = getUuid();
    const message = {
      id,
      inboxId,
      content,
      status: MESSAGE_STATUS.PROGRESS,
      isUserMessage: true,
      message_type: MESSAGE_TYPE.INCOMING,
      conversationId,
    };
    commit('pushMessageToConversations', message);
    sendMessageAPI(inboxId, accountId, contactId, content)
      .then(({ data }) => {
        // If current conversation is temporary, use the one from API
        const { conversation_id: apiConversationId } =
          conversationId === DEFAULT_CONVERSATION ? data : params;
        if (conversationId === DEFAULT_CONVERSATION) {
          commit('updateConversationId', {
            apiConversationId,
            oldConversationId: DEFAULT_CONVERSATION,
          });
          const iframeMessage = {
            event: 'setLastConversation',
            data: apiConversationId,
          };
          window.parent.postMessage(JSON.stringify(iframeMessage), '*');
          commit('auth/setLastConversation', apiConversationId, { root: true });
        }
        commit('updateMessageStatusToSuccess', { apiConversationId, id });
      })
      .catch(() => {
        const { conversation_id: apiConversationId } =
          conversationId === DEFAULT_CONVERSATION;
        commit('updateMessageStatusToFailed', { apiConversationId, id });
      });
  },

  fetchOldConversations({ commit }, params) {
    const { lastConversation } = params;
    getConversationAPI(lastConversation)
      .then(({ data }) => {
        const { payload } = data;
        commit('initMessagesInConversation', { lastConversation, payload });
      })
      .catch(() => {
        // commit('updateMessageStatusToFailed', { lastConversation, id });
      });
  },
};

const mutations = {
  initInboxInConversations($state, lastConversation) {
    Vue.set($state.conversations, lastConversation, {});
  },

  pushMessageToConversations($state, message) {
    const { id, conversationId } = message;
    const messagesInbox = $state.conversations[conversationId];
    console.log(messagesInbox, conversationId);
    Vue.set(messagesInbox, id, message);
  },

  initMessagesInConversation($state, { payload, lastConversation }) {
    const conversationStore = $state.conversations[lastConversation];
    payload.map(message => Vue.set(conversationStore, message.id, message));
    console.log($state, lastConversation);
    // conversationStore = {
    //   ...conversationStore,
    //   ...messagesHash,
    // };
  },

  updateConversationId($state, data) {
    const { oldConversationId, apiConversationId } = data;
    const conversation = $state.conversations[oldConversationId];
    Vue.set($state.conversations, apiConversationId, conversation);
    Vue.delete($state.conversations, oldConversationId);
  },

  updateMessageStatusToSuccess($state, data) {
    const { apiConversationId, id } = data;
    $state.conversations[apiConversationId][id].status = MESSAGE_STATUS.SUCCESS;
  },

  updateMessageStatusToFailed($state, data) {
    const { apiConversationId, id } = data;
    $state.conversations[apiConversationId][id].status = MESSAGE_STATUS.FAILED;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
