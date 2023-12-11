import {
  MESSAGE_TYPE,
  CONVERSATION_PRIORITY_ORDER,
} from 'shared/constants/messages';
import { applyPageFilters } from './helpers';

export const getSelectedChatConversation = ({
  allConversations,
  selectedChatId,
}) =>
  allConversations.filter(conversation => conversation.id === selectedChatId);

const sortComparator = {
  latest: (a, b, sortOrder) =>
    sortOrder === 'asc'
      ? a.last_activity_at - b.last_activity_at
      : b.last_activity_at - a.last_activity_at,
  sort_on_created_at: (a, b, sortOrder) =>
    sortOrder === 'asc'
      ? a.created_at - b.created_at
      : b.created_at - a.created_at,
  sort_on_priority: (a, b, sortOrder) => {
    const diff =
      CONVERSATION_PRIORITY_ORDER[a.priority] -
      CONVERSATION_PRIORITY_ORDER[b.priority];
    return sortOrder === 'asc' ? diff : -diff;
  },
  sort_on_waiting_since: (a, b, sortOrder) => {
    if (!a.waiting_since && !b.waiting_since) {
      return sortOrder === 'asc'
        ? a.created_at - b.created_at
        : b.created_at - a.created_at;
    }
    if (!a.waiting_since) {
      return sortOrder === 'asc' ? 1 : -1;
    }
    if (!b.waiting_since) {
      return sortOrder === 'asc' ? -1 : 1;
    }

    // Normal comparison logic with sort order
    const diff = a.waiting_since - b.waiting_since;
    return sortOrder === 'asc' ? diff : -diff;
  },
};
// getters
const getters = {
  getAllConversations: ({
    allConversations,
    chatSortFilter,
    chatSortOrderFilter,
  }) => {
    return allConversations.sort((a, b) =>
      sortComparator[chatSortFilter](a, b, chatSortOrderFilter)
    );
  },
  getSelectedChat: ({ selectedChatId, allConversations }) => {
    const selectedChat = allConversations.find(
      conversation => conversation.id === selectedChatId
    );
    return selectedChat || {};
  },
  getSelectedChatAttachments: (_state, _getters) => {
    const selectedChat = _getters.getSelectedChat;
    return selectedChat.attachments || [];
  },
  getLastEmailInSelectedChat: (stage, _getters) => {
    const selectedChat = _getters.getSelectedChat;
    const { messages = [] } = selectedChat;
    const lastEmail = [...messages].reverse().find(message => {
      const {
        content_attributes: contentAttributes = {},
        message_type: messageType,
      } = message;
      const { email = {} } = contentAttributes;
      const isIncomingOrOutgoing =
        messageType === MESSAGE_TYPE.OUTGOING ||
        messageType === MESSAGE_TYPE.INCOMING;
      if (email.from && isIncomingOrOutgoing) {
        return true;
      }
      return false;
    });

    return lastEmail;
  },
  getMineChats: (_state, _, __, rootGetters) => activeFilters => {
    const currentUserID = rootGetters.getCurrentUser?.id;

    return _state.allConversations.filter(conversation => {
      const { assignee } = conversation.meta;
      const isAssignedToMe = assignee && assignee.id === currentUserID;
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      const isChatMine = isAssignedToMe && shouldFilter;

      return isChatMine;
    });
  },
  getAppliedConversationFilters: _state => {
    return _state.appliedFilters;
  },
  getUnAssignedChats: _state => activeFilters => {
    return _state.allConversations.filter(conversation => {
      const isUnAssigned = !conversation.meta.assignee;
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      return isUnAssigned && shouldFilter;
    });
  },
  getAllStatusChats: _state => activeFilters => {
    return _state.allConversations.filter(conversation => {
      const shouldFilter = applyPageFilters(conversation, activeFilters);
      return shouldFilter;
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
  getChatSortOrderFilter: ({ chatSortOrderFilter }) => chatSortOrderFilter,
  getConversationById: _state => conversationId => {
    return _state.allConversations.find(
      value => value.id === Number(conversationId)
    );
  },
  getConversationParticipants: _state => {
    return _state.conversationParticipants;
  },
  getConversationLastSeen: _state => {
    return _state.conversationLastSeen;
  },
};

export default getters;
