import Vue from 'vue';
import types from '../../mutation-types';
import getters, { getSelectedChatConversation } from './getters';
import actions from './actions';
import { findPendingMessageIndex } from './helpers';
import { MESSAGE_STATUS } from 'shared/constants/messages';
import wootConstants from 'dashboard/constants/globals';
import { BUS_EVENTS } from '../../../../shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';

const state = {
  allConversations: [],
  listLoadingStatus: true,
  chatStatusFilter: wootConstants.STATUS_TYPE.OPEN,
  chatSortFilter: wootConstants.SORT_BY_TYPE.LATEST,
  currentInbox: null,
  selectedChatId: null,
  appliedFilters: [],
  contextMenuChatId: null,
  conversationParticipants: [],
  conversationLastSeen: null,
  syncConversationsMessages: {},
  conversationFilters: {},
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
      } else if (conversation.id !== _state.selectedChatId) {
        // If the conversation is already in the list, replace it
        // Added this to fix the issue of the conversation not being updated
        // When reconnecting to the websocket. If the selectedChatId is not the same as
        // the conversation.id in the store, replace the existing conversation with the new one
        newAllConversations[indexInCurrentList] = conversation;
      } else {
        // If the conversation is already in the list and selectedChatId is the same,
        // replace all data except the messages array, attachments, dataFetched, allMessagesLoaded
        const existingConversation = newAllConversations[indexInCurrentList];
        newAllConversations[indexInCurrentList] = {
          ...conversation,
          allMessagesLoaded: existingConversation.allMessagesLoaded,
          messages: existingConversation.messages,
          dataFetched: existingConversation.dataFetched,
          attachments: existingConversation.attachments,
        };
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
  [types.SET_ALL_ATTACHMENTS](_state, { id, data }) {
    const [chat] = _state.allConversations.filter(c => c.id === id);
    if (!chat) return;
    Vue.set(chat, 'attachments', []);
    chat.attachments.push(...data);
  },
  [types.SET_MISSING_MESSAGES](_state, { id, data }) {
    const [chat] = _state.allConversations.filter(c => c.id === id);
    if (!chat) return;
    Vue.set(chat, 'messages', data);
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

  [types.UPDATE_CONVERSATION_LAST_ACTIVITY](
    _state,
    { lastActivityAt, conversationId }
  ) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    if (chat) {
      Vue.set(chat, 'last_activity_at', lastActivityAt);
    }
  },
  [types.ASSIGN_PRIORITY](_state, { priority, conversationId }) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    Vue.set(chat, 'priority', priority);
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

  [types.ADD_CONVERSATION_ATTACHMENTS]({ allConversations }, message) {
    const { conversation_id: conversationId } = message;
    const [chat] = getSelectedChatConversation({
      allConversations,
      selectedChatId: conversationId,
    });

    if (!chat) return;

    const isMessageSent =
      message.status === MESSAGE_STATUS.SENT && message.attachments;
    if (isMessageSent) {
      message.attachments.forEach(attachment => {
        if (!chat.attachments.some(a => a.id === attachment.id)) {
          chat.attachments.push(attachment);
        }
      });
    }
  },

  [types.DELETE_CONVERSATION_ATTACHMENTS]({ allConversations }, message) {
    const { conversation_id: conversationId } = message;
    const [chat] = getSelectedChatConversation({
      allConversations,
      selectedChatId: conversationId,
    });

    if (!chat) return;

    const isMessageSent = message.status === MESSAGE_STATUS.SENT;
    if (isMessageSent) {
      const attachmentIndex = chat.attachments.findIndex(
        a => a.message_id === message.id
      );
      if (attachmentIndex !== -1) chat.attachments.splice(attachmentIndex, 1);
    }
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
      const { conversation: { unread_count: unreadCount = 0 } = {} } = message;
      chat.unread_count = unreadCount;
      if (selectedChatId === conversationId) {
        emitter.emit(BUS_EVENTS.FETCH_LABEL_SUGGESTIONS);
        emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
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
        emitter.emit(BUS_EVENTS.FETCH_LABEL_SUGGESTIONS);
        emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
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

  [types.UPDATE_MESSAGE_UNREAD_COUNT](
    _state,
    { id, lastSeen, unreadCount = 0 }
  ) {
    const [chat] = _state.allConversations.filter(c => c.id === id);
    if (chat) {
      Vue.set(chat, 'agent_last_seen_at', lastSeen);
      Vue.set(chat, 'unread_count', unreadCount);
    }
  },
  [types.CHANGE_CHAT_STATUS_FILTER](_state, data) {
    _state.chatStatusFilter = data;
  },

  [types.CHANGE_CHAT_SORT_FILTER](_state, data) {
    _state.chatSortFilter = data;
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

  [types.SET_LAST_MESSAGE_ID_IN_SYNC_CONVERSATION](
    _state,
    { conversationId, messageId }
  ) {
    _state.syncConversationsMessages[conversationId] = messageId;
  },

  [types.SET_CONTEXT_MENU_CHAT_ID](_state, chatId) {
    _state.contextMenuChatId = chatId;
  },

  [types.SET_CHAT_LIST_FILTERS](_state, data) {
    _state.conversationFilters = data;
  },
  [types.UPDATE_CHAT_LIST_FILTERS](_state, data) {
    _state.conversationFilters = { ..._state.conversationFilters, ...data };
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
