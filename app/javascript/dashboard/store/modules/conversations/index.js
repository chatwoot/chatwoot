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
  attachments: {},
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
  copilotAssistant: {},
  // Separate storage for sidebar counts
  sidebarCountsData: [],
};

// mutations
export const mutations = {
  [types.SET_ALL_CONVERSATION](_state, payload) {
    // Handle both old format (array) and new format (object with conversations and replace flag)
    const conversationList = Array.isArray(payload)
      ? payload
      : payload.conversations;
    const shouldReplace = payload.replace === true;

    if (shouldReplace && conversationList.length > 0) {
      // Only replace if we have new data to avoid clearing counts
      _state.allConversations = conversationList;
    } else if (!shouldReplace) {
      // Add/update conversations (for pagination or updates)
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
          };
        }
      });
      _state.allConversations = newAllConversations;
    }
  },
  [types.EMPTY_ALL_CONVERSATION](_state) {
    // Don't clear conversations immediately to avoid flickering
    // They will be replaced when new data arrives
    _state.selectedChatId = null;
  },

  [types.UPDATE_CONVERSATIONS_FOR_COUNTS](_state, conversations) {
    // Store sidebar counts data separately from main conversations
    _state.sidebarCountsData = conversations.map(conv => ({
      id: conv.id,
      unread_count: conv.unread_count || 0,
      labels: conv.labels || [],
      inbox_id: conv.inbox_id,
      team_id: conv.meta?.team?.id,
      status: conv.status,
      assignee_id: conv.meta?.assignee?.id,
    }));
  },
  [types.SET_ALL_MESSAGES_LOADED](_state) {
    const [chat] = getSelectedChatConversation(_state);
    chat.allMessagesLoaded = true;
  },

  [types.CLEAR_ALL_MESSAGES_LOADED](_state) {
    const [chat] = getSelectedChatConversation(_state);
    chat.allMessagesLoaded = false;
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
    _state.attachments[id] = [...data];
  },
  [types.SET_MISSING_MESSAGES](_state, { id, data }) {
    const [chat] = _state.allConversations.filter(c => c.id === id);
    if (!chat) return;
    chat.messages = data;
  },

  [types.SET_CURRENT_CHAT_WINDOW](_state, activeChat) {
    if (activeChat) {
      _state.selectedChatId = activeChat.id;
    }
  },

  [types.ASSIGN_AGENT](_state, assignee) {
    const [chat] = getSelectedChatConversation(_state);
    chat.meta.assignee = assignee;
  },

  [types.ASSIGN_TEAM](_state, { team, conversationId }) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    chat.meta.team = team;
  },

  [types.UPDATE_CONVERSATION_LAST_ACTIVITY](
    _state,
    { lastActivityAt, conversationId }
  ) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    if (chat) {
      chat.last_activity_at = lastActivityAt;
    }
  },
  [types.ASSIGN_PRIORITY](_state, { priority, conversationId }) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    chat.priority = priority;
  },

  [types.UPDATE_CONVERSATION_CUSTOM_ATTRIBUTES](_state, custom_attributes) {
    const [chat] = getSelectedChatConversation(_state);
    chat.custom_attributes = custom_attributes;
  },

  [types.CHANGE_CONVERSATION_STATUS](
    _state,
    { conversationId, status, snoozedUntil, resolutionReason }
  ) {
    const conversation =
      getters.getConversationById(_state)(conversationId) || {};
    conversation.snoozed_until = snoozedUntil;
    conversation.status = status;
    if (resolutionReason !== undefined) {
      conversation.resolution_reason = resolutionReason;
    }
  },

  [types.MUTE_CONVERSATION](_state) {
    const [chat] = getSelectedChatConversation(_state);
    chat.muted = true;
  },

  [types.UNMUTE_CONVERSATION](_state) {
    const [chat] = getSelectedChatConversation(_state);
    chat.muted = false;
  },

  [types.ADD_CONVERSATION_ATTACHMENTS](_state, message) {
    // early return if the message has not been sent, or has no attachments
    if (
      message.status !== MESSAGE_STATUS.SENT ||
      !message.attachments?.length
    ) {
      return;
    }

    const id = message.conversation_id;
    const existingAttachments = _state.attachments[id] || [];

    const attachmentsToAdd = message.attachments.filter(attachment => {
      // if the attachment is not already in the store, add it
      // this is to prevent duplicates
      return !existingAttachments.some(
        existingAttachment => existingAttachment.id === attachment.id
      );
    });

    // replace the attachments in the store
    _state.attachments[id] = [...existingAttachments, ...attachmentsToAdd];
  },

  [types.DELETE_CONVERSATION_ATTACHMENTS](_state, message) {
    if (message.status !== MESSAGE_STATUS.SENT) return;

    const { conversation_id: id } = message;
    const existingAttachments = _state.attachments[id] || [];
    if (!existingAttachments.length) return;

    _state.attachments[id] = existingAttachments.filter(attachment => {
      return attachment.message_id !== message.id;
    });
  },

  [types.ADD_MESSAGE](_state, message) {
    const { conversation_id: conversationId } = message;
    const [chat] = getSelectedChatConversation({
      allConversations: _state.allConversations,
      selectedChatId: conversationId,
    });
    if (!chat) return;

    const pendingMessageIndex = findPendingMessageIndex(chat, message);
    if (pendingMessageIndex !== -1) {
      chat.messages[pendingMessageIndex] = message;
    } else {
      chat.messages.push(message);
      chat.timestamp = message.created_at;
      const {
        conversation: {
          unread_count: unreadCount = 0,
          unread_count_full: unreadCountFull,
        } = {},
      } = message;
      chat.unread_count = unreadCount;
      if (unreadCountFull !== undefined) {
        chat.unread_count_full = unreadCountFull;
      }
      // Update sidebar counts if conversation exists there
      const sidebarItem = _state.sidebarCountsData.find(
        c => c.id === conversationId
      );
      if (sidebarItem) {
        sidebarItem.unread_count = unreadCount;
      }
      if (_state.selectedChatId === conversationId) {
        emitter.emit(BUS_EVENTS.FETCH_LABEL_SUGGESTIONS);
        emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
      }
    }
  },

  [types.ADD_CONVERSATION](_state, conversation) {
    _state.allConversations.push(conversation);
    // Also add to sidebar counts if needed
    if (!_state.sidebarCountsData.find(c => c.id === conversation.id)) {
      _state.sidebarCountsData.push({
        id: conversation.id,
        unread_count: conversation.unread_count || 0,
        labels: conversation.labels || [],
        inbox_id: conversation.inbox_id,
        team_id: conversation.meta?.team?.id,
        status: conversation.status,
        assignee_id: conversation.meta?.assignee?.id,
      });
    }
  },

  [types.DELETE_CONVERSATION](_state, conversationId) {
    _state.allConversations = _state.allConversations.filter(
      c => c.id !== conversationId
    );
    // Also remove from sidebar counts data
    _state.sidebarCountsData = _state.sidebarCountsData.filter(
      c => c.id !== conversationId
    );
  },

  [types.UPDATE_CONVERSATION](_state, conversation) {
    const { allConversations } = _state;
    const index = allConversations.findIndex(c => c.id === conversation.id);

    if (index > -1) {
      const selectedConversation = allConversations[index];

      // ignore out of order events
      if (conversation.updated_at < selectedConversation.updated_at) {
        return;
      }

      const { messages, ...updates } = conversation;
      allConversations[index] = { ...selectedConversation, ...updates };

      // Update sidebar counts data
      const sidebarItem = _state.sidebarCountsData.find(
        c => c.id === conversation.id
      );
      if (sidebarItem) {
        sidebarItem.unread_count = conversation.unread_count || 0;
        sidebarItem.labels = conversation.labels || [];
        sidebarItem.team_id = conversation.meta?.team?.id;
        sidebarItem.status = conversation.status;
        sidebarItem.assignee_id = conversation.meta?.assignee?.id;
      } else {
        _state.sidebarCountsData.push({
          id: conversation.id,
          unread_count: conversation.unread_count || 0,
          labels: conversation.labels || [],
          inbox_id: conversation.inbox_id,
          team_id: conversation.meta?.team?.id,
        });
      }
      if (_state.selectedChatId === conversation.id) {
        emitter.emit(BUS_EVENTS.FETCH_LABEL_SUGGESTIONS);
        emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
      }
    } else {
      _state.allConversations.push(conversation);
      // Also add to sidebar counts if new
      if (!_state.sidebarCountsData.find(c => c.id === conversation.id)) {
        _state.sidebarCountsData.push({
          id: conversation.id,
          unread_count: conversation.unread_count || 0,
          labels: conversation.labels || [],
          inbox_id: conversation.inbox_id,
          team_id: conversation.meta?.team?.id,
        });
      }
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
    { id, lastSeen, unreadCount = 0, unreadCountFull }
  ) {
    const [chat] = _state.allConversations.filter(c => c.id === id);
    if (chat) {
      chat.agent_last_seen_at = lastSeen;
      chat.unread_count = unreadCount;
      if (unreadCountFull !== undefined) {
        chat.unread_count_full = unreadCountFull;
      }
    }
    // Also update sidebar counts
    const sidebarItem = _state.sidebarCountsData.find(c => c.id === id);
    if (sidebarItem) {
      sidebarItem.unread_count = unreadCount;
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
    chat.meta.assignee = payload.assignee;
  },

  [types.UPDATE_CONVERSATION_CONTACT](_state, { conversationId, ...payload }) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    if (chat) {
      chat.meta.sender = payload;
    }
  },

  [types.SET_ACTIVE_INBOX](_state, inboxId) {
    _state.currentInbox = inboxId ? parseInt(inboxId, 10) : null;
  },

  [types.SET_CONVERSATION_CAN_REPLY](_state, { conversationId, canReply }) {
    const [chat] = _state.allConversations.filter(c => c.id === conversationId);
    if (chat) {
      chat.can_reply = canReply;
    }
  },

  [types.CLEAR_CONTACT_CONVERSATIONS](_state, contactId) {
    const chats = _state.allConversations.filter(
      c => c.meta.sender.id !== contactId
    );
    _state.allConversations = chats;
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
  [types.SET_INBOX_CAPTAIN_ASSISTANT](_state, data) {
    _state.copilotAssistant = data.assistant;
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
