import { MESSAGE_TYPE } from 'widget/helpers/constants';
import groupBy from 'lodash.groupby';
import { groupConversationBySender } from './helpers';
import { formatUnixDate } from 'shared/helpers/DateHelper';

export const getters = {
  isAllMessagesFetched: _state => conversationId =>
    _state.conversations[conversationId].uiFlags.allFetched,
  isCreating: _state => _state.uiFlags.isCreating,
  isAgentTypingIn: _state => conversationId =>
    _state.conversations[conversationId].uiFlags.isAgentTyping,
  allConversations: _state =>
    _state.conversations.allIds.map(id => _state.conversations.byId[id]),
  totalConversationsLength: _state => _state.conversations.allIds.length,
  firstMessageIn: (...getterArguments) => conversationId => {
    const { _state, _rootGetters } = getterArguments;
    const messagesInConversation =
      _state.conversations.byId[conversationId].messages;
    if (messagesInConversation.length) {
      const messageId = messagesInConversation[0];
      const lastMessage = _rootGetters.messageV2.getMessageById(messageId);
      return lastMessage;
    }
    return {};
  },
  groupByMessagesIn: (...getterArguments) => conversationId => {
    const { _state, _rootGetters } = getterArguments;
    const messageIds = _state.conversations.byId[conversationId].messages;
    const messagesInConversation = messageIds.map(messageId =>
      _rootGetters.messageV2.getMessageById(messageId)
    );
    const conversationGroupedByDate = groupBy(messagesInConversation, message =>
      formatUnixDate(message.created_at)
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
    const count = Object.values(_state.conversations).filter(chat => {
      const { created_at: createdAt, message_type: messageType } = chat;
      const isOutGoing = messageType === MESSAGE_TYPE.OUTGOING;
      const hasNotSeen = userLastSeenAt
        ? createdAt * 1000 > userLastSeenAt * 1000
        : true;
      return hasNotSeen && isOutGoing;
    }).length;
    return count;
  },
  getUnreadTextMessages: (_state, _getters) => {
    const unreadCount = _getters.getUnreadMessageCount;
    const allMessages = [...Object.values(_state.conversations)];
    const unreadAgentMessages = allMessages.filter(message => {
      const { message_type: messageType } = message;
      return messageType === MESSAGE_TYPE.OUTGOING;
    });
    const maxUnreadCount = Math.min(unreadCount, 3);
    const allUnreadMessages = unreadAgentMessages.splice(-maxUnreadCount);
    return allUnreadMessages;
  },
};
