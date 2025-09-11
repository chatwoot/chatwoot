import { MESSAGE_TYPE } from 'widget/helpers/constants';
import { groupBy } from 'widget/helpers/utils';
import { groupConversationBySender } from './helpers';
import { formatUnixDate } from 'shared/helpers/DateHelper';

export const getters = {
  getAllMessagesLoaded: _state => _state.uiFlags.allMessagesLoaded,
  getIsCreating: _state => _state.uiFlags.isCreating,
  getIsAgentTyping: _state => _state.uiFlags.isAgentTyping,
  getConversation: _state => _state.conversations,
  getConversationSize: _state => Object.keys(_state.conversations).length,
  getEarliestMessage: _state => {
    const conversation = Object.values(_state.conversations);
    if (conversation.length) {
      return conversation[0];
    }
    return {};
  },
  getLastMessage: _state => {
    const conversation = Object.values(_state.conversations);
    if (conversation.length) {
      return conversation[conversation.length - 1];
    }
    return {};
  },
  getGroupedConversation: _state => {
    const conversationGroupedByDate = groupBy(
      Object.values(_state.conversations),
      message => formatUnixDate(message.created_at)
    );
    return Object.keys(conversationGroupedByDate).map(date => ({
      date,
      messages: groupConversationBySender(conversationGroupedByDate[date]),
    }));
  },
  getIsFetchingList: _state => _state.uiFlags.isFetchingList,
  getMessageCount: _state => {
    return Object.values(_state.conversations).length;
  },
  getUnreadMessageCount: _state => {
    const { userLastSeenAt } = _state.meta;
    return Object.values(_state.conversations).filter(chat => {
      const { created_at: createdAt, message_type: messageType } = chat;
      const isOutGoing = messageType === MESSAGE_TYPE.OUTGOING;
      const hasNotSeen = userLastSeenAt
        ? createdAt * 1000 > userLastSeenAt * 1000
        : true;
      return hasNotSeen && isOutGoing;
    }).length;
  },
  getUnreadTextMessages: (_state, _getters) => {
    const unreadCount = _getters.getUnreadMessageCount;
    const allMessages = [...Object.values(_state.conversations)];
    const unreadAgentMessages = allMessages.filter(message => {
      const { message_type: messageType } = message;
      return messageType === MESSAGE_TYPE.OUTGOING;
    });
    const maxUnreadCount = Math.min(unreadCount, 3);
    return unreadAgentMessages.splice(-maxUnreadCount);
  },
  getAttachmentCount: _state => {
    const allMessages = Object.values(_state.conversations);
    return allMessages.reduce((count, message) => {
      if (message.attachments && message.attachments.length > 0) {
        return count + message.attachments.length;
      }
      return count;
    }, 0);
  },
  getAttachmentLimit: () => {
    // Default to 10, could be made configurable later
    return 10;
  },
  getRemainingAttachments: (_state, _getters) => {
    const limit = _getters.getAttachmentLimit;
    const current = _getters.getAttachmentCount;
    return Math.max(0, limit - current);
  },
  isAttachmentLimitReached: (_state, _getters) => {
    return _getters.getRemainingAttachments === 0;
  },
};
