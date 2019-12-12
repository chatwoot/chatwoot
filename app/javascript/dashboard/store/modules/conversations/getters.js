import authAPI from '../../../api/auth';

export const getSelectedChatConversation = ({
  allConversations,
  selectedChat,
}) =>
  allConversations.filter(conversation => conversation.id === selectedChat.id);

// getters
const getters = {
  getAllConversations: ({ allConversations }) => allConversations,
  getSelectedChat: ({ selectedChat }) => selectedChat,
  getMineChats(_state) {
    const currentUserID = authAPI.getCurrentUser().id;
    return _state.allConversations.filter(chat =>
      chat.meta.assignee === null
        ? false
        : chat.status === _state.chatStatusFilter &&
          chat.meta.assignee.id === currentUserID
    );
  },
  getUnAssignedChats(_state) {
    return _state.allConversations.filter(
      chat =>
        chat.meta.assignee === null && chat.status === _state.chatStatusFilter
    );
  },
  getAllStatusChats(_state) {
    return _state.allConversations.filter(
      chat => chat.status === _state.chatStatusFilter
    );
  },
  getChatListLoadingStatus: ({ listLoadingStatus }) => listLoadingStatus,
  getAllMessagesLoaded(_state) {
    const [chat] = getSelectedChatConversation(_state);
    return chat.allMessagesLoaded === undefined
      ? false
      : chat.allMessagesLoaded;
  },
  getUnreadCount(_state) {
    const [chat] = getSelectedChatConversation(_state);
    return chat.messages.filter(
      chatMessage =>
        chatMessage.created_at * 1000 > chat.agent_last_seen_at * 1000 &&
        (chatMessage.message_type === 0 && chatMessage.private !== true)
    ).length;
  },
  getChatStatusFilter: ({ chatStatusFilter }) => chatStatusFilter,
  getSelectedInbox: ({ currentInbox }) => currentInbox,
  getConvTabStats: ({ convTabStats }) => convTabStats,
};

export default getters;
