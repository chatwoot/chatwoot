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
  isFetchingConversationsList: _state =>
    _state.conversations.uiFlags.isFetching,
  allConversations: (...getterArguments) => {
    const [_state, , , _rootGetters] = getterArguments;
    const conversations = _state.conversations.allIds.map(id => {
      const conversation = _state.conversations.byId[id];
      const messagesInConversation = conversation.messages.map(messageId => {
        const lastMessage = _rootGetters['messageV2/messageById'](messageId);
        return lastMessage;
      });
      return {
        ...conversation,
        messages: messagesInConversation,
      };
    });
    return conversations;
  },
  totalConversationsLength: _state => _state.conversations.allIds.length || 0,
  firstMessageIn: (...getterArguments) => conversationId => {
    const [_state, , , _rootGetters] = getterArguments;
    const messagesInConversation =
      _state.conversations.byId[conversationId].messages;
    if (messagesInConversation.length) {
      const messageId = messagesInConversation[0];
      const lastMessage = _rootGetters['messageV2/messageById'](messageId);
      return lastMessage;
    }
    return {};
  },
  groupByMessagesIn: (...getterArguments) => conversationId => {
    const [_state, , , _rootGetters] = getterArguments;
    const messageIds = _state.conversations.byId[conversationId].messages;
    const messagesInConversation = messageIds.map(messageId =>
      _rootGetters['messageV2/messageById'](messageId)
    );
    const messagesGroupedByDate = groupBy(messagesInConversation, message =>
      formatUnixDate(message.created_at)
    );
    return Object.keys(messagesGroupedByDate).map(date => ({
      date,
      messages: groupConversationBySender(messagesGroupedByDate[date]),
    }));
  },
  isFetchingMessages: _state => conversationId => {
    const hasConversation = _state.conversations.uiFlags.byId[conversationId];
    return hasConversation ? hasConversation.isFetching : false;
  },
  allMessagesCountIn: _state => conversationId => {
    const conversation = _state.conversations.byId[conversationId];
    return conversation ? conversation.messages.length : 0;
  },
  unreadMessageCountIn: (...getterArguments) => conversationId => {
    const [_state, , , _rootGetters] = getterArguments;
    const conversation = _state.conversations.byId[conversationId];
    if (conversation) return 0;

    const messageIds = _state.conversations.byId[conversationId].messages;
    const messagesInConversation = messageIds.map(messageId =>
      _rootGetters['messageV2/messageById'](messageId)
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
  getConversationById: (...getterArguments) => conversationId => {
    const [_state, , , _rootGetters] = getterArguments;
    const conversation = _state.conversations.byId[conversationId];

    if (!conversation) return undefined;

    const messageIds = conversation.messages;
    const messagesInConversation = messageIds.map(messageId => {
      const lastMessage = _rootGetters['messageV2/messageById'](messageId);
      return lastMessage;
    });
    return {
      ...conversation,
      messages: messagesInConversation,
    };
  },
  getUnreadMessagesIn: (...getterArguments) => conversationId => {
    const [_state, _getters, , _rootGetters] = getterArguments;
    const unreadCount = _getters.unreadMessageCountIn(conversationId);
    const conversation = _state.conversations.byId[conversationId];
    if (conversation) return 0;

    const messageIds = _state.conversations.byId[conversationId].messages;
    const messagesInConversation = messageIds.map(messageId =>
      _rootGetters['messageV2/messageById'](messageId)
    );
    const unreadAgentMessages = messagesInConversation.filter(message => {
      const { message_type: messageType } = message;
      return messageType === MESSAGE_TYPE.OUTGOING;
    });
    const maxUnreadCount = Math.min(unreadCount, 3);
    const allUnreadMessages = unreadAgentMessages.splice(-maxUnreadCount);
    return allUnreadMessages;
  },
  lastActiveConversationId: (...getterArguments) => {
    const [_state, _getters] = getterArguments;

    const size = _getters.totalConversationsLength;
    const conversation = _state.conversations.allIds[size - 1];

    if (conversation) {
      return conversation;
    }
    return undefined;
  },
};
