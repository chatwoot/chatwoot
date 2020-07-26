/* eslint no-console: 0 */
/* eslint no-param-reassign: 0 */
import Vue from 'vue';
import * as types from '../../mutation-types';
import getters, { getSelectedChatConversation } from './getters';
import actions from './actions';
import wootConstants from '../../../constants';

const state = {
  allConversations: [],
  listLoadingStatus: true,
  chatStatusFilter: wootConstants.STATUS_TYPE.OPEN,
  currentInbox: null,
  selectedChatId: null,
};

// mutations
export const mutations = {
  [types.default.SET_ALL_CONVERSATION](_state, conversationList) {
    const newAllConversations = [..._state.allConversations];
    conversationList.forEach(conversation => {
      const indexInCurrentList = newAllConversations.findIndex(
        c => c.id === conversation.id
      );
      if (indexInCurrentList < 0) {
        newAllConversations.push(conversation);
      }
    });
    _state.allConversations = newAllConversations;
  },
  [types.default.EMPTY_ALL_CONVERSATION](_state) {
    _state.allConversations = [];
    _state.selectedChatId = null;
  },
  [types.default.SET_ALL_MESSAGES_LOADED](_state) {
    const [chat] = getSelectedChatConversation(_state);
    Vue.set(chat, 'allMessagesLoaded', true);
  },

  [types.default.CLEAR_ALL_MESSAGES_LOADED](_state) {
    const [chat] = getSelectedChatConversation(_state);
    Vue.set(chat, 'allMessagesLoaded', false);
  },
  [types.default.CLEAR_CURRENT_CHAT_WINDOW](_state) {
    _state.selectedChatId = null;
  },

  [types.default.SET_PREVIOUS_CONVERSATIONS](_state, { id, data }) {
    if (data.length) {
      const [chat] = _state.allConversations.filter(c => c.id === id);
      chat.messages.unshift(...data);
    }
  },

  [types.default.SET_CURRENT_CHAT_WINDOW](_state, activeChat) {
    if (activeChat) {
      _state.selectedChatId = activeChat.id;
    }
  },

  [types.default.ASSIGN_AGENT](_state, assignee) {
    const [chat] = getSelectedChatConversation(_state);
    chat.meta.assignee = assignee;
  },

  [types.default.RESOLVE_CONVERSATION](_state, status) {
    const [chat] = getSelectedChatConversation(_state);
    chat.status = status;
  },

  [types.default.MUTE_CONVERSATION](_state) {
    const [chat] = getSelectedChatConversation(_state);
    chat.muted = true;
  },

  [types.default.SEND_MESSAGE](_state, currentMessage) {
    const [chat] = getSelectedChatConversation(_state);
    const allMessagesExceptCurrent = (chat.messages || []).filter(
      message => message.id !== currentMessage.id
    );
    allMessagesExceptCurrent.push(currentMessage);
    chat.messages = allMessagesExceptCurrent;
  },

  [types.default.ADD_MESSAGE](_state, message) {
    const [chat] = _state.allConversations.filter(
      c => c.id === message.conversation_id
    );
    if (!chat) return;
    const previousMessageIndex = chat.messages.findIndex(
      m => m.id === message.id
    );
    if (previousMessageIndex === -1) {
      chat.messages.push(message);
      if (_state.selectedChatId === message.conversation_id) {
        window.bus.$emit('scrollToMessage');
      }
    } else {
      chat.messages[previousMessageIndex] = message;
    }
  },

  [types.default.ADD_CONVERSATION](_state, conversation) {
    _state.allConversations.push(conversation);
  },

  [types.default.UPDATE_CONVERSATION](_state, conversation) {
    const { allConversations } = _state;
    const currentConversationIndex = allConversations.findIndex(
      c => c.id === conversation.id
    );
    if (currentConversationIndex > -1) {
      const { messages, ...conversationAttributes } = conversation;
      const currentConversation = {
        ...allConversations[currentConversationIndex],
        ...conversationAttributes,
      };
      Vue.set(allConversations, currentConversationIndex, currentConversation);
      if (_state.selectedChatId === conversation.id) {
        window.bus.$emit('scrollToMessage');
      }
    } else {
      _state.allConversations.push(conversation);
    }
  },

  [types.default.SET_LIST_LOADING_STATUS](_state) {
    _state.listLoadingStatus = true;
  },

  [types.default.CLEAR_LIST_LOADING_STATUS](_state) {
    _state.listLoadingStatus = false;
  },

  [types.default.MARK_MESSAGE_READ](_state, { id, lastSeen }) {
    const [chat] = _state.allConversations.filter(c => c.id === id);
    chat.agent_last_seen_at = lastSeen;
  },

  [types.default.CHANGE_CHAT_STATUS_FILTER](_state, data) {
    _state.chatStatusFilter = data;
  },

  // Update assignee on action cable message
  [types.default.UPDATE_ASSIGNEE](_state, payload) {
    const [chat] = _state.allConversations.filter(c => c.id === payload.id);
    chat.meta.assignee = payload.assignee;
  },

  [types.default.UPDATE_CONVERSATION_CONTACT](
    _state,
    { conversationId, ...payload }
  ) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    if (chat) {
      Vue.set(chat.meta, 'sender', payload);
    }
  },

  [types.default.SET_ACTIVE_INBOX](_state, inboxId) {
    _state.currentInbox = inboxId ? parseInt(inboxId, 10) : null;
  },

  [types.default.SET_CONVERSATION_CAN_REPLY](
    _state,
    { conversationId, canReply }
  ) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    if (chat) {
      Vue.set(chat, 'can_reply', canReply);
    }
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
