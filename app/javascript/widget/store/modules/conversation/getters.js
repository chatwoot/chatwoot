import { MESSAGE_TYPE } from 'widget/helpers/constants';
import { groupBy } from 'widget/helpers/utils';
import {
  chronological,
  groupConversationBySender,
  isPersisted,
} from './helpers';
import { formatUnixDate } from 'shared/helpers/DateHelper';

export const getters = {
  getAllMessagesLoaded: _state => _state.uiFlags.allMessagesLoaded,
  getIsCreating: _state => _state.uiFlags.isCreating,
  getIsAgentTyping: _state => _state.uiFlags.isAgentTyping,
  getPendingTyping: _state => _state.pendingTyping,
  getConversation: _state => _state.conversations,
  getConversationSize: _state => Object.keys(_state.conversations).length,
  // The `before` cursor for older pages, so the earliest stored message, never a temporary one.
  getEarliestMessage: _state =>
    chronological(_state.conversations).find(isPersisted) || {},
  getLastMessage: _state => {
    const conversation = chronological(_state.conversations);
    if (conversation.length) {
      return conversation[conversation.length - 1];
    }
    return {};
  },
  getGroupedConversation: _state => {
    const conversationGroupedByDate = groupBy(
      chronological(_state.conversations),
      message => formatUnixDate(message.created_at)
    );
    return Object.keys(conversationGroupedByDate).map(date => ({
      date,
      messages: groupConversationBySender(conversationGroupedByDate[date]),
    }));
  },
  getPendingCustomAttributes: _state => _state.pendingCustomAttributes,
  getPendingLabels: _state => _state.pendingLabels,
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
    const allMessages = chronological(_state.conversations);
    const unreadAgentMessages = allMessages.filter(message => {
      const { message_type: messageType } = message;
      return messageType === MESSAGE_TYPE.OUTGOING;
    });
    const maxUnreadCount = Math.min(unreadCount, 3);
    return unreadAgentMessages.splice(-maxUnreadCount);
  },
};
