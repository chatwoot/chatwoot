import authAPI from '../../../api/auth';
import { applyPageFilters } from './helpers';

export const getSelectedChatConversation = ({
  allConversations,
  selectedChatId,
}) =>
  allConversations.filter(conversation => conversation.id === selectedChatId);

// getters
const getters = {
  getAllConversations: ({ allConversations }) =>
    allConversations.sort(
      (a, b) => b.messages.last()?.created_at - a.messages.last()?.created_at
    ),
  getSelectedChat: ({ selectedChatId, allConversations }) => {
    const selectedChat = allConversations.find(
      conversation => conversation.id === selectedChatId
    );
    return selectedChat || {};
  },
  getMineChats: _state => activeFilters => {
    const currentUserID = authAPI.getCurrentUser().id;

    return _state.allConversations.filter(chat => {
      const hasAssignee = !!chat.meta.assignee;
      const isAssignedToMe = chat.meta.assignee.id === currentUserID;
      const shouldFilter = applyPageFilters(chat, activeFilters);
      const isChatMine = hasAssignee && isAssignedToMe && shouldFilter;

      return isChatMine;
    });
  },
  getUnAssignedChats: _state => activeFilters => {
    return _state.allConversations.filter(chat => {
      const isUnAssigned = !chat.meta.assignee;
      const shouldFilter = applyPageFilters(chat, activeFilters);
      return isUnAssigned && shouldFilter;
    });
  },
  getAllStatusChats: _state => activeFilters => {
    return _state.allConversations.filter(chat => {
      const shouldFilter = applyPageFilters(chat, activeFilters);
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
  getSelectedInbox: ({ currentInbox }) => currentInbox,
};

export default getters;
