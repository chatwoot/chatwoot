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
    const messagesGroupedByDate = groupBy(messagesInConversation, message =>
      formatUnixDate(message.created_at)
    );
    return Object.keys(messagesGroupedByDate).map(date => ({
      date,
      messages: groupConversationBySender(messagesGroupedByDate[date]),
    }));
  },
  isFetchingMessages: _state => conversationId =>
    _state.conversations[conversationId].uiFlags.isFetching,
  allMessagesCountIn: _state => conversationId => {
    return _state.conversations.byId[conversationId].messages.length;
  },
  unreadMessageCountIn: (...getterArguments) => conversationId => {
    const { _state, _rootGetters } = getterArguments;
    const conversation = _state.conversations.byId[conversationId];
    if (conversation) return 0;

    const messageIds = _state.conversations.byId[conversationId].messages;
    const messagesInConversation = messageIds.map(messageId =>
      _rootGetters.messageV2.getMessageById(messageId)
    );
    const { meta: { userLastSeenAt } = {} } = conversation;
    const count = messagesInConversation.filter(message => {
      const { created_at: createdAt, message_type: messageType } = message;
      const isOutGoing = messageType === MESSAGE_TYPE.OUTGOING;
      const hasNotSeen = userLastSeenAt
        ? createdAt * 1000 > userLastSeenAt * 1000
        : true;
      return hasNotSeen && isOutGoing;
    }).length;
    return count;
  },
  getUnreadMessagesIn: (...getterArguments) => conversationId => {
    const {
      state: _state,
      getters: _getters,
      rootGetters: _rootGetters,
    } = getterArguments;
    const unreadCount = _getters.unreadMessageCountIn(conversationId);
    const conversation = _state.conversations.byId[conversationId];
    if (conversation) return 0;

    const messageIds = _state.conversations.byId[conversationId].messages;
    const messagesInConversation = messageIds.map(messageId =>
      _rootGetters.messageV2.getMessageById(messageId)
    );
    const unreadAgentMessages = messagesInConversation.filter(message => {
      const { message_type: messageType } = message;
      return messageType === MESSAGE_TYPE.OUTGOING;
    });
    const maxUnreadCount = Math.min(unreadCount, 3);
    const allUnreadMessages = unreadAgentMessages.splice(-maxUnreadCount);
    return allUnreadMessages;
  },
};
