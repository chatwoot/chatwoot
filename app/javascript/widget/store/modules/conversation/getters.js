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
  // New getter for filtered conversation that respects should_show_message_on_chat flag
  getFilteredGroupedConversation: _state => {
    const allMessages = Object.values(_state.conversations);

    // Filter messages based on should_show_message_on_chat flag
    const filteredMessages = allMessages.filter(message => {
      const { content_attributes } = message;
      // Show message if should_show_message_on_chat is true or undefined
      // Hide message if should_show_message_on_chat is explicitly false
      return (
        !content_attributes ||
        content_attributes.should_show_message_on_chat !== false
      );
    });

    const conversationGroupedByDate = groupBy(filteredMessages, message =>
      formatUnixDate(message.created_at)
    );
    return Object.keys(conversationGroupedByDate).map(date => ({
      date,
      messages: groupConversationBySender(conversationGroupedByDate[date]),
    }));
  },
  getLastMessage: _state => {
    const allMessages = Object.values(_state.conversations);

    // Filter messages based on should_show_message_on_chat flag
    const filteredMessages = allMessages.filter(message => {
      const { content_attributes } = message;
      // Show message if should_show_message_on_chat is true or undefined
      // Hide message if should_show_message_on_chat is explicitly false
      return (
        !content_attributes ||
        content_attributes.should_show_message_on_chat !== false
      );
    });

    const conversation = filteredMessages;
    if (conversation.length) {
      return conversation[conversation.length - 1];
    }
    return {};
  },
  getIsFetchingList: _state => _state.uiFlags.isFetchingList,
  getMessageCount: _state => {
    return Object.values(_state.conversations).length;
  },
  getUnreadMessageCount: (_state, _getters) => {
    // If there are AI nudge messages, return 0 for regular unread count
    // This ensures AI nudge messages take priority
    if (_getters.hasAINudgeMessages) {
      return 0;
    }

    const { userLastSeenAt } = _state.meta;
    return Object.values(_state.conversations).filter(chat => {
      const {
        created_at: createdAt,
        message_type: messageType,
        content_attributes,
      } = chat;
      const isOutGoing = messageType === MESSAGE_TYPE.OUTGOING;
      const hasNotSeen = userLastSeenAt
        ? createdAt * 1000 > userLastSeenAt * 1000
        : true;
      const isNotAINudge =
        !content_attributes || content_attributes.is_ai_nudge !== true;
      return hasNotSeen && isOutGoing && isNotAINudge;
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
  // New getter to check if there are any AI nudge messages
  hasAINudgeMessages: _state => {
    const { userLastSeenAt } = _state.meta;
    const allMessages = Object.values(_state.conversations);

    return allMessages.some(message => {
      const {
        content_attributes,
        created_at: createdAt,
        message_type: messageType,
      } = message;
      const isAINudge =
        content_attributes && content_attributes.is_ai_nudge === true;
      const isOutGoing = messageType === MESSAGE_TYPE.OUTGOING;
      const hasNotSeen = userLastSeenAt
        ? createdAt * 1000 > userLastSeenAt * 1000
        : true;

      return isAINudge && isOutGoing && hasNotSeen;
    });
  },
  // New getter to get AI nudge messages
  getAINudgeMessages: _state => {
    const { userLastSeenAt } = _state.meta;
    const allMessages = Object.values(_state.conversations);

    const aiNudgeMessages = allMessages.filter(message => {
      const {
        content_attributes,
        created_at: createdAt,
        message_type: messageType,
      } = message;
      const isAINudge =
        content_attributes && content_attributes.is_ai_nudge === true;
      const isOutGoing = messageType === MESSAGE_TYPE.OUTGOING;
      const hasNotSeen = userLastSeenAt
        ? createdAt * 1000 > userLastSeenAt * 1000
        : true;

      // For AI nudge messages, consider them unread regardless of timestamp
      const isAINudgeUnread = isAINudge ? true : hasNotSeen;

      return isAINudge && isOutGoing && isAINudgeUnread;
    });

    return aiNudgeMessages;
  },
  // Updated getter to prioritize AI nudge messages over regular unread messages
  getUnreadMessagesForDisplay: (_state, _getters) => {
    // Check if there are AI nudge messages
    const hasAINudge = _getters.hasAINudgeMessages;

    if (hasAINudge) {
      const aiNudgeMessages = _getters.getAINudgeMessages;
      return aiNudgeMessages;
    }
    // Otherwise, return regular unread messages
    return _getters.getUnreadTextMessages;
  },
  // Getter for total unread count including AI nudge messages
  getTotalUnreadCount: (_state, _getters) => {
    const hasAINudge = _getters.hasAINudgeMessages;

    if (hasAINudge) {
      const aiNudgeMessages = _getters.getAINudgeMessages;
      return aiNudgeMessages.length;
    }
    return _getters.getUnreadMessageCount;
  },
};
