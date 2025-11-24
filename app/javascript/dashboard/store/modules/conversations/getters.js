import { MESSAGE_TYPE } from 'shared/constants/messages';
import { applyPageFilters, applyRoleFilter, sortComparator } from './helpers';
import filterQueryGenerator from 'dashboard/helper/filterQueryGenerator';
import { matchesFilters } from './helpers/filterHelpers';
import {
  getUserPermissions,
  getUserRole,
} from '../../../helper/permissionsHelper';
import camelcaseKeys from 'camelcase-keys';

const DEFAULT_TAB = 'all';

const normalizeTabKey = tabKey => tabKey || DEFAULT_TAB;

const buildOrderedIdListForTab = (state, tabKey) => {
  const tabPages = state.conversationPagesByTab[normalizeTabKey(tabKey)];
  if (!tabPages) {
    return [];
  }
  const seen = new Set();
  const orderedIds = [];
  Object.keys(tabPages)
    .map(page => Number(page))
    .sort((a, b) => a - b)
    .forEach(pageNumber => {
      const ids = tabPages[String(pageNumber)] || [];
      ids.forEach(id => {
        if (!seen.has(id)) {
          seen.add(id);
          orderedIds.push(id);
        }
      });
    });
  return orderedIds;
};

const conversationsFromIds = (state, ids) =>
  ids.map(id => state.conversationsById[id]).filter(Boolean);

const buildTabList = (state, tabKey) => {
  const orderedIds = buildOrderedIdListForTab(state, tabKey);
  return conversationsFromIds(state, orderedIds);
};

const buildAllConversationList = state => {
  const flattenIds = Object.values(state.conversationPagesByTab).reduce(
    (acc, tabPages) => {
      Object.values(tabPages).forEach(pageIds => {
        pageIds.forEach(id => {
          if (!acc.set.has(id)) {
            acc.set.add(id);
            acc.ids.push(id);
          }
        });
      });
      return acc;
    },
    { set: new Set(), ids: [] }
  );

  if (!flattenIds.ids.length) {
    return Object.values(state.conversationsById);
  }

  return conversationsFromIds(state, flattenIds.ids);
};

export const getSelectedChatConversation = ({
  conversationsById,
  selectedChatId,
}) => {
  const chat = conversationsById[selectedChatId];
  return chat ? [chat] : [];
};

const getters = {
  getAllConversations: state => {
    const list = buildTabList(state, DEFAULT_TAB);
    if (!list.length) {
      return buildAllConversationList(state);
    }
    return [...list].sort((a, b) => sortComparator(a, b, state.chatSortFilter));
  },
  getFilteredConversations: (state, _, __, rootGetters) => {
    const currentUser = rootGetters.getCurrentUser;
    const currentUserId = rootGetters.getCurrentUser.id;
    const currentAccountId = rootGetters.getCurrentAccountId;

    const permissions = getUserPermissions(currentUser, currentAccountId);
    const userRole = getUserRole(currentUser, currentAccountId);

    const baseList = buildTabList(state, 'appliedFilters').length
      ? buildTabList(state, 'appliedFilters')
      : buildAllConversationList(state);

    return baseList
      .filter(conversation => {
        const matchesFilterResult = matchesFilters(
          conversation,
          state.appliedFilters
        );
        const allowedForRole = applyRoleFilter(
          conversation,
          userRole,
          permissions,
          currentUserId
        );

        return matchesFilterResult && allowedForRole;
      })
      .sort((a, b) => sortComparator(a, b, state.chatSortFilter));
  },
  getSelectedChat: ({ selectedChatId, conversationsById }) => {
    return conversationsById[selectedChatId] || {};
  },
  getSelectedChatAttachments: ({ selectedChatId, attachments }) => {
    return attachments[selectedChatId] || [];
  },
  getChatListFilters: ({ conversationFilters }) => conversationFilters,
  getLastEmailInSelectedChat: (stage, _getters) => {
    const selectedChat = _getters.getSelectedChat;
    const { messages = [] } = selectedChat;
    const lastEmail = [...messages].reverse().find(message => {
      const { message_type: messageType } = message;
      if (message.private) return false;

      return [MESSAGE_TYPE.OUTGOING, MESSAGE_TYPE.INCOMING].includes(
        messageType
      );
    });

    return lastEmail;
  },
  getMineChats: (state, _, __, rootGetters) => activeFilters => {
    const currentUserID = rootGetters.getCurrentUser?.id;
    const sourceList = buildTabList(state, 'me').length
      ? buildTabList(state, 'me')
      : buildAllConversationList(state);

    return sourceList.filter(conversation => {
      const { assignee } = conversation.meta;
      const isAssignedToMe = assignee && assignee.id === currentUserID;
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      const isChatMine = isAssignedToMe && shouldFilter;

      return isChatMine;
    });
  },
  getAppliedConversationFiltersV2: _state => {
    // TODO: Replace existing one with V2 after migrating the filters to use camelcase
    return _state.appliedFilters.map(camelcaseKeys);
  },
  getAppliedConversationFilters: _state => {
    return _state.appliedFilters;
  },
  getAppliedConversationFiltersQuery: _state => {
    const hasAppliedFilters = _state.appliedFilters.length !== 0;
    return hasAppliedFilters ? filterQueryGenerator(_state.appliedFilters) : [];
  },
  getUnAssignedChats: state => activeFilters => {
    const sourceList = buildTabList(state, 'unassigned').length
      ? buildTabList(state, 'unassigned')
      : buildAllConversationList(state);

    return sourceList.filter(conversation => {
      const isUnAssigned = !conversation.meta.assignee;
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      return isUnAssigned && shouldFilter;
    });
  },
  getAllStatusChats: (state, _, __, rootGetters) => activeFilters => {
    const currentUser = rootGetters.getCurrentUser;
    const currentUserId = rootGetters.getCurrentUser.id;
    const currentAccountId = rootGetters.getCurrentAccountId;

    const permissions = getUserPermissions(currentUser, currentAccountId);
    const userRole = getUserRole(currentUser, currentAccountId);
    const sourceList = buildTabList(state, DEFAULT_TAB).length
      ? buildTabList(state, DEFAULT_TAB)
      : buildAllConversationList(state);

    return sourceList.filter(conversation => {
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      const allowedForRole = applyRoleFilter(
        conversation,
        userRole,
        permissions,
        currentUserId
      );

      return shouldFilter && allowedForRole;
    });
  },
  getChatListLoadingStatus: ({ listLoadingStatus }) => listLoadingStatus,
  getAllMessagesLoaded(_state) {
    const [chat] = getSelectedChatConversation(_state);
    return !chat || chat.allMessagesLoaded === undefined
      ? false
      : chat.allMessagesLoaded;
  },
  getUnreadCount(_state) {
    const [chat] = getSelectedChatConversation(_state);
    if (!chat) return [];
    return chat.messages.filter(
      chatMessage =>
        chatMessage.created_at * 1000 > chat.agent_last_seen_at * 1000 &&
        chatMessage.message_type === 0 &&
        chatMessage.private !== true
    ).length;
  },
  getChatStatusFilter: ({ chatStatusFilter }) => chatStatusFilter,
  getChatSortFilter: ({ chatSortFilter }) => chatSortFilter,
  getSelectedInbox: ({ currentInbox }) => currentInbox,
  getConversationById: state => conversationId => {
    return state.conversationsById[Number(conversationId)] || null;
  },
  getConversationParticipants: _state => {
    return _state.conversationParticipants;
  },
  getConversationLastSeen: _state => {
    return _state.conversationLastSeen;
  },

  getContextMenuChatId: _state => {
    return _state.contextMenuChatId;
  },

  getCopilotAssistant: _state => {
    return _state.copilotAssistant;
  },
};

export default getters;
