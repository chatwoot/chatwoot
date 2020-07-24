import authAPI from '../../../api/auth';

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
  getNextChatConversation: _state => {
    const [selectedChat] = getSelectedChatConversation(_state);
    const conversations = getters.getAllStatusChats(_state);
    if (conversations.length <= 1) {
      return null;
    }
    const currentIndex = conversations.findIndex(
      conversation => conversation.id === selectedChat.id
    );
    const nextIndex = (currentIndex + 1) % conversations.length;
    return conversations[nextIndex];
  },
};

export default getters;
