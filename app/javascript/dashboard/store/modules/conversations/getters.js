import {
  isAssignedToMe,
  hasAssignee,
  canBeCountedForUnread,
} from '../../utils/conversation';

const getters = {
  getConversation: $state => id => $state.records[Number(id)] || {},
  getConversations: ({ records }) => {
    const conversations = Object.values(records);
    return conversations.sort((m1, m2) => m2.timestamp - m1.timestamp);
  },
  getCurrentStatusConversations(_, appGetters) {
    const currentStatus =
      appGetters['conversationFilter/getCurrentConversationStatus'];
    return appGetters.getConversations.filter(
      chat => chat.status === currentStatus
    );
  },
  getMineChats(_, appGetters) {
    const currentUserID = appGetters.getCurrentUserID;
    const conversations = appGetters.getCurrentStatusConversations;
    return conversations.filter(conversation =>
      isAssignedToMe(conversation, currentUserID)
    );
  },
  getUnAssignedChats(_, appGetters) {
    const conversations = appGetters.getCurrentStatusConversations;
    return conversations.filter(conversation => !hasAssignee(conversation));
  },
  getAllStatusChats(_, appGetters) {
    const conversations = appGetters.getCurrentStatusConversations;
    return conversations;
  },
  getCurrentAssigneeConversations(_, appGetters) {
    const currentAssigneeType =
      appGetters['conversationFilter/getCurrentAssigneeType'];
    if (currentAssigneeType === 'me') {
      return appGetters.getMineChats;
    }
    if (currentAssigneeType === 'unassigned') {
      return appGetters.getUnAssignedChats;
    }
    return appGetters.getAllStatusChats;
  },
  getUnreadCount(_, appGetters) {
    const conversationId =
      appGetters['conversationFilter/getCurrentConversationId'];
    const conversation = appGetters.getConversation(conversationId);

    if (!conversation.id) {
      return 0;
    }

    const messages = appGetters['messages/getMessages'](conversationId);
    return messages.filter(message =>
      canBeCountedForUnread(message, conversation)
    ).length;
  },
  isConversationListLoading: ({ uiFlags: { isFetching } }) => isFetching,
};

export default getters;
