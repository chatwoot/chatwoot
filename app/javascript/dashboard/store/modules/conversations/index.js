import Vue from 'vue';
import types from '../../mutation-types';
import getters, { getSelectedChatConversation } from './getters';
import actions from './actions';
import { findPendingMessageIndex } from './helpers';
import wootConstants from '../../../constants';
import { BUS_EVENTS } from '../../../../shared/constants/busEvents';

const state = {
  allConversations: [],
  listLoadingStatus: true,
  chatStatusFilter: wootConstants.STATUS_TYPE.OPEN,
  currentInbox: null,
  selectedChatId: null,
  appliedFilters: [],
};

// mutations
export const mutations = {
  [types.SET_ALL_CONVERSATION](_state, conversationList) {
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
  [types.EMPTY_ALL_CONVERSATION](_state) {
    _state.allConversations = [];
    _state.selectedChatId = null;
  },
  [types.SET_ALL_MESSAGES_LOADED](_state) {
    const [chat] = getSelectedChatConversation(_state);
    Vue.set(chat, 'allMessagesLoaded', true);
  },

  [types.CLEAR_ALL_MESSAGES_LOADED](_state) {
    const [chat] = getSelectedChatConversation(_state);
    Vue.set(chat, 'allMessagesLoaded', false);
  },
  [types.CLEAR_CURRENT_CHAT_WINDOW](_state) {
    _state.selectedChatId = null;
  },

  [types.SET_PREVIOUS_CONVERSATIONS](_state, { id, data }) {
    if (data.length) {
      const [chat] = _state.allConversations.filter(c => c.id === id);
      chat.messages.unshift(...data);
    }
  },

  [types.SET_CURRENT_CHAT_WINDOW](_state, activeChat) {
    if (activeChat) {
      _state.selectedChatId = activeChat.id;
    }
  },

  [types.ASSIGN_AGENT](_state, assignee) {
    const [chat] = getSelectedChatConversation(_state);
    Vue.set(chat.meta, 'assignee', assignee);
  },

  [types.ASSIGN_TEAM](_state, { team, conversationId }) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    Vue.set(chat.meta, 'team', team);
  },

  [types.UPDATE_CONVERSATION_CUSTOM_ATTRIBUTES](_state, custom_attributes) {
    const [chat] = getSelectedChatConversation(_state);
    Vue.set(chat, 'custom_attributes', custom_attributes);
  },

  [types.CHANGE_CONVERSATION_STATUS](
    _state,
    { conversationId, status, snoozedUntil }
  ) {
    const conversation =
      getters.getConversationById(_state)(conversationId) || {};
    Vue.set(conversation, 'snoozed_until', snoozedUntil);
    Vue.set(conversation, 'status', status);
  },

  [types.MUTE_CONVERSATION](_state) {
    const [chat] = getSelectedChatConversation(_state);
    Vue.set(chat, 'muted', true);
  },

  [types.UNMUTE_CONVERSATION](_state) {
    const [chat] = getSelectedChatConversation(_state);
    Vue.set(chat, 'muted', false);
  },

  [types.ADD_MESSAGE]({ allConversations, selectedChatId }, message) {
    const { conversation_id: conversationId } = message;
    const [chat] = getSelectedChatConversation({
      allConversations,
      selectedChatId: conversationId,
    });
    if (!chat) return;

    const pendingMessageIndex = findPendingMessageIndex(chat, message);
    if (pendingMessageIndex !== -1) {
      Vue.set(chat.messages, pendingMessageIndex, message);
    } else {
      chat.messages.push(message);
      chat.timestamp = message.created_at;
      if (selectedChatId === conversationId) {
        window.bus.$emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
      }
    }
  },

  [types.ADD_CONVERSATION](_state, conversation) {
    _state.allConversations.push(conversation);
  },

  [types.UPDATE_CONVERSATION](_state, conversation) {
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
        window.bus.$emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
      }
    } else {
      _state.allConversations.push(conversation);
    }
  },

  [types.SET_LIST_LOADING_STATUS](_state) {
    _state.listLoadingStatus = true;
  },

  [types.CLEAR_LIST_LOADING_STATUS](_state) {
    _state.listLoadingStatus = false;
  },

  [types.MARK_MESSAGE_READ](_state, { id, lastSeen }) {
    const [chat] = _state.allConversations.filter(c => c.id === id);
    if (chat) {
      chat.agent_last_seen_at = lastSeen;
    }
  },

  [types.CHANGE_CHAT_STATUS_FILTER](_state, data) {
    _state.chatStatusFilter = data;
  },

  // Update assignee on action cable message
  [types.UPDATE_ASSIGNEE](_state, payload) {
    const [chat] = _state.allConversations.filter(c => c.id === payload.id);
    Vue.set(chat.meta, 'assignee', payload.assignee);
  },

  [types.UPDATE_CONVERSATION_CONTACT](_state, { conversationId, ...payload }) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    if (chat) {
      Vue.set(chat.meta, 'sender', payload);
    }
  },

  [types.SET_ACTIVE_INBOX](_state, inboxId) {
    _state.currentInbox = inboxId ? parseInt(inboxId, 10) : null;
  },

  [types.SET_CONVERSATION_CAN_REPLY](_state, { conversationId, canReply }) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    if (chat) {
      Vue.set(chat, 'can_reply', canReply);
    }
  },

  [types.CLEAR_CONTACT_CONVERSATIONS](_state, contactId) {
    const chats = _state.allConversations.filter(
      c => c.meta.sender.id !== contactId
    );
    Vue.set(_state, 'allConversations', chats);
  },

  [types.SET_CONVERSATION_FILTERS](_state, data) {
    _state.appliedFilters = data;
  },

  [types.CLEAR_CONVERSATION_FILTERS](_state) {
    _state.appliedFilters = [];
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
