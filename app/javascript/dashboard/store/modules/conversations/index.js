import types from '../../mutation-types';
import getters, { getSelectedChatConversation } from './getters';
import actions from './actions';
import { findPendingMessageIndex, sortComparator } from './helpers';
import { MESSAGE_STATUS } from 'shared/constants/messages';
import wootConstants from 'dashboard/constants/globals';
import { BUS_EVENTS } from '../../../../shared/constants/busEvents';
import { emitter } from 'shared/helpers/mitt';

const DEFAULT_TAB = 'all';
const DEFAULT_PAGE = 1;
const DEFAULT_PAGE_SIZE = 25;

const normalizeTabKey = tab => tab || DEFAULT_TAB;

const clonePagesWithUpdate = (pagesByTab, tabKey, updater) => {
  const normalizedTab = normalizeTabKey(tabKey);
  const existingTabPages = pagesByTab[normalizedTab] || {};
  const nextTabPages = updater(existingTabPages);
  if (nextTabPages === existingTabPages) {
    return pagesByTab;
  }
  return {
    ...pagesByTab,
    [normalizedTab]: nextTabPages,
  };
};

const removeIdFromTabPages = (tabPages, conversationId) => {
  let mutated = false;
  const nextPages = Object.entries(tabPages).reduce((acc, [pageKey, ids]) => {
    const filteredIds = ids.filter(id => id !== conversationId);
    if (filteredIds.length !== ids.length) {
      mutated = true;
      acc[pageKey] = filteredIds;
    } else {
      acc[pageKey] = ids;
    }
    return acc;
  }, {});
  return mutated ? nextPages : tabPages;
};

const removeIdFromAllTabs = (pagesByTab, conversationId) => {
  let mutated = false;
  const nextPagesByTab = Object.entries(pagesByTab).reduce(
    (acc, [tabKey, tabPages]) => {
      const updatedTabPages = removeIdFromTabPages(tabPages, conversationId);
      if (updatedTabPages !== tabPages) {
        mutated = true;
      }
      acc[tabKey] = updatedTabPages;
      return acc;
    },
    {}
  );
  return mutated ? nextPagesByTab : pagesByTab;
};

const rebuildTabPagesWithConversation = (_state, tabKey, conversationId) => {
  _state.conversationPagesByTab = clonePagesWithUpdate(
    _state.conversationPagesByTab,
    tabKey,
    tabPages => {
      const existingTabPages = Object.keys(tabPages).length
        ? tabPages
        : { [String(DEFAULT_PAGE)]: [] };

      const pageNumbers = Object.keys(existingTabPages)
        .map(key => Number(key))
        .sort((a, b) => a - b);

      const collectedIds = [];
      const seen = new Set();

      pageNumbers.forEach(pageNumber => {
        const ids = existingTabPages[String(pageNumber)] || [];
        ids.forEach(id => {
          if (id === conversationId) {
            return;
          }
          if (!seen.has(id)) {
            seen.add(id);
            collectedIds.push(id);
          }
        });
      });

      collectedIds.push(conversationId);

      const conversations = collectedIds
        .map(id => _state.conversationsById[id])
        .filter(Boolean);

      if (!conversations.length) {
        return pageNumbers.reduce((acc, pageNumber) => {
          acc[String(pageNumber)] = [];
          return acc;
        }, {});
      }

      const sorted = conversations
        .slice()
        .sort((a, b) => sortComparator(a, b, _state.chatSortFilter));

      const sortedIds = sorted.map(item => item.id);

      const nextPages = {};
      pageNumbers.forEach((pageNumber, index) => {
        const startIndex = index * DEFAULT_PAGE_SIZE;
        nextPages[String(pageNumber)] = sortedIds.slice(
          startIndex,
          startIndex + DEFAULT_PAGE_SIZE
        );
      });

      return nextPages;
    }
  );
};

const upsertConversationEntity = (_state, conversation) => {
  const existing = _state.conversationsById[conversation.id];
  let updatedConversation = conversation;

  if (existing) {
    if (conversation.id === _state.selectedChatId) {
      updatedConversation = {
        ...conversation,
        allMessagesLoaded: existing.allMessagesLoaded,
        messages: existing.messages,
        dataFetched: existing.dataFetched,
      };
    } else {
      updatedConversation = { ...existing, ...conversation };
    }
  }

  _state.conversationsById = {
    ..._state.conversationsById,
    [conversation.id]: updatedConversation,
  };
};

const state = {
  conversationsById: {},
  conversationPagesByTab: {},
  filtersByTab: {},
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
};

// mutations
export const mutations = {
  [types.SET_ALL_CONVERSATION](_state, { tab, page, conversations }) {
    const pageNumber = page || DEFAULT_PAGE;
    const tabKey = normalizeTabKey(tab);
    const conversationIds = conversations.map(conversation => {
      upsertConversationEntity(_state, conversation);
      return conversation.id;
    });

    _state.conversationPagesByTab = clonePagesWithUpdate(
      _state.conversationPagesByTab,
      tabKey,
      tabPages => ({
        ...tabPages,
        [String(pageNumber)]: conversationIds,
      })
    );
  },
  [types.EMPTY_ALL_CONVERSATION](_state) {
    _state.conversationsById = {};
    _state.conversationPagesByTab = {};
    _state.filtersByTab = {};
    _state.selectedChatId = null;
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
    if (!data.length) {
      return;
    }

    const chat = _state.conversationsById[id];
    if (!chat) {
      return;
    }

    chat.messages = [...data, ...(chat.messages || [])];
  },
  [types.SET_ALL_ATTACHMENTS](_state, { id, data }) {
    _state.attachments[id] = [...data];
  },
  [types.SET_MISSING_MESSAGES](_state, { id, data }) {
    const chat = _state.conversationsById[id];
    if (!chat) {
      return;
    }
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
    const chat = _state.conversationsById[conversationId];
    if (chat) {
      chat.meta.team = team;
    }
  },

  [types.UPDATE_CONVERSATION_LAST_ACTIVITY](
    _state,
    { lastActivityAt, conversationId }
  ) {
    const chat = _state.conversationsById[conversationId];
    if (!chat) {
      return;
    }
    chat.last_activity_at = lastActivityAt;
  },
  [types.ASSIGN_PRIORITY](_state, { priority, conversationId }) {
    const chat = _state.conversationsById[conversationId];
    if (chat) {
      chat.priority = priority;
    }
  },

  [types.UPDATE_CONVERSATION_CUSTOM_ATTRIBUTES](_state, custom_attributes) {
    const [chat] = getSelectedChatConversation(_state);
    chat.custom_attributes = custom_attributes;
  },

  [types.CHANGE_CONVERSATION_STATUS](
    _state,
    { conversationId, status, snoozedUntil }
  ) {
    const conversation =
      getters.getConversationById(_state)(conversationId) || {};
    conversation.snoozed_until = snoozedUntil;
    conversation.status = status;
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
    const chat = _state.conversationsById[conversationId];
    if (!chat) {
      return;
    }

    const pendingMessageIndex = findPendingMessageIndex(chat, message);
    if (pendingMessageIndex !== -1) {
      chat.messages[pendingMessageIndex] = message;
      return;
    }

    chat.messages.push(message);
    chat.timestamp = message.created_at;
    const { conversation: { unread_count: unreadCount = 0 } = {} } = message;
    chat.unread_count = unreadCount;
    if (_state.selectedChatId === conversationId) {
      emitter.emit(BUS_EVENTS.FETCH_LABEL_SUGGESTIONS);
      emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
    }
  },

  [types.ADD_CONVERSATION](_state, { conversation, tabKeys = [DEFAULT_TAB] }) {
    upsertConversationEntity(_state, conversation);

    tabKeys.forEach(tabKey => {
      rebuildTabPagesWithConversation(_state, tabKey, conversation.id);
    });
  },

  [types.DELETE_CONVERSATION](_state, conversationId) {
    const { [conversationId]: removed, ...rest } = _state.conversationsById;
    if (!removed) {
      return;
    }
    _state.conversationsById = rest;
    _state.conversationPagesByTab = removeIdFromAllTabs(
      _state.conversationPagesByTab,
      conversationId
    );
  },

  [types.UPDATE_CONVERSATION](
    _state,
    { conversation, tabKeys = [DEFAULT_TAB] }
  ) {
    const existingConversation = _state.conversationsById[conversation.id];

    if (existingConversation) {
      if (
        conversation.updated_at &&
        existingConversation.updated_at &&
        conversation.updated_at < existingConversation.updated_at
      ) {
        return;
      }

      const { messages, ...updates } = conversation;
      const mergedConversation = {
        ...existingConversation,
        ...updates,
      };
      _state.conversationsById = {
        ..._state.conversationsById,
        [conversation.id]: mergedConversation,
      };
    } else {
      upsertConversationEntity(_state, conversation);
    }

    _state.conversationPagesByTab = removeIdFromAllTabs(
      _state.conversationPagesByTab,
      conversation.id
    );

    tabKeys.forEach(tabKey => {
      rebuildTabPagesWithConversation(_state, tabKey, conversation.id);
    });

    if (_state.selectedChatId === conversation.id) {
      emitter.emit(BUS_EVENTS.FETCH_LABEL_SUGGESTIONS);
      emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
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
    const chat = _state.conversationsById[id];
    if (chat) {
      chat.agent_last_seen_at = lastSeen;
      chat.unread_count = unreadCount;
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
    const chat = _state.conversationsById[payload.id];
    if (chat) {
      chat.meta.assignee = payload.assignee;
    }
  },

  [types.UPDATE_CONVERSATION_CONTACT](_state, { conversationId, ...payload }) {
    const chat = _state.conversationsById[conversationId];
    if (chat) {
      chat.meta.sender = payload;
    }
  },

  [types.SET_ACTIVE_INBOX](_state, inboxId) {
    _state.currentInbox = inboxId ? parseInt(inboxId, 10) : null;
  },

  [types.SET_CONVERSATION_CAN_REPLY](_state, { conversationId, canReply }) {
    const chat = _state.conversationsById[conversationId];
    if (chat) {
      chat.can_reply = canReply;
    }
  },

  [types.CLEAR_CONTACT_CONVERSATIONS](_state, contactId) {
    const remaining = {};
    const removedIds = [];
    Object.values(_state.conversationsById).forEach(conversation => {
      if (conversation.meta?.sender?.id === contactId) {
        removedIds.push(conversation.id);
      } else {
        remaining[conversation.id] = conversation;
      }
    });

    if (!removedIds.length) {
      return;
    }

    _state.conversationsById = remaining;
    removedIds.forEach(conversationId => {
      _state.conversationPagesByTab = removeIdFromAllTabs(
        _state.conversationPagesByTab,
        conversationId
      );
    });
  },

  [types.SET_CONVERSATION_FILTERS](_state, data) {
    _state.appliedFilters = data;
  },

  [types.SET_CONVERSATION_TAB_FILTERS](_state, { tab, filters }) {
    const normalizedTab = normalizeTabKey(tab);
    const { page, ...rest } = filters || {};
    _state.filtersByTab = {
      ..._state.filtersByTab,
      [normalizedTab]: rest,
    };
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
