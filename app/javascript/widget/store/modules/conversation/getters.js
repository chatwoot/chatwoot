import { MESSAGE_TYPE } from 'widget/helpers/constants';
import groupBy from 'lodash.groupby';
import { groupConversationBySender } from './helpers';
import { formatUnixDate } from 'shared/helpers/DateHelper';

export const getters = {
  uiFlagsIn: _state => conversationId => {
    const uiFlags = _state.conversations.uiFlags.byId[conversationId];

    if (uiFlags) return uiFlags;
    return {
      allFetched: false,
      isAgentTyping: false,
      isFetching: false,
    };
  },
  metaIn: _state => conversationId => {
    const meta = _state.conversations.meta.byId[conversationId];
    if (meta) return meta;
    return {
      userLastSeenAt: undefined,
    };
  },
  isAllMessagesFetchedIn: (...getterArguments) => conversationId => {
    const [, _getters] = getterArguments;
    const uiFlags = _getters.uiFlagsIn(conversationId);

    if (uiFlags) return uiFlags.allFetched;
    return false;
  },
  isCreating: _state => _state.uiFlags.conversations.isCreating,
  isAgentTypingIn: (...getterArguments) => conversationId => {
    const [, _getters] = getterArguments;
    const uiFlags = _getters.uiFlagsIn(conversationId);

    if (uiFlags) return uiFlags.isAgentTyping;
    return false;
  },
  isFetchingConversationsList: _state =>
    _state.conversations.uiFlags.isFetching,
  allConversations: (...getterArguments) => {
    const [_state, , , _rootGetters] = getterArguments;
    const conversations = _state.conversations.allIds.map(id => {
      const conversation = _state.conversations.byId[id];
      const messagesInConversation = conversation.messages.map(messageId => {
        const lastMessage = _rootGetters['message/messageById'](messageId);
        return lastMessage;
      });
      return {
        ...conversation,
        messages: messagesInConversation,
      };
    });
    return conversations;
  },
  allActiveConversations: (...getterArguments) => {
    const [, _getters] = getterArguments;

    const conversations = _getters.allConversations
      .filter(conversation => conversation.status === 'open')
      .sort((a, b) => {
        const lastMessageOnA = a.messages[a.messages.length - 1];
        const lastMessageOnB = b.messages[b.messages.length - 1];
        return lastMessageOnB.created_at - lastMessageOnA.created_at;
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
      const lastMessage = _rootGetters['message/messageById'](messageId);
      return lastMessage;
    }
    return {};
  },
  groupByMessagesIn: (...getterArguments) => conversationId => {
    const [_state, , , _rootGetters] = getterArguments;
    const conversation = _state.conversations.byId[conversationId];
    const messageIds = conversation ? conversation.messages : [];
    const messagesInConversation = messageIds.map(messageId =>
      _rootGetters['message/messageById'](messageId)
    );
    const messagesGroupedByDate = groupBy(messagesInConversation, message =>
      formatUnixDate(message.created_at)
    );
    return Object.keys(messagesGroupedByDate).map(date => ({
      date,
      messages: groupConversationBySender(messagesGroupedByDate[date]),
    }));
  },
  isFetchingMessagesIn: _state => conversationId => {
    const hasConversation = _state.conversations.uiFlags.byId[conversationId];
    return hasConversation ? hasConversation.isFetching : false;
  },
  allMessagesCountIn: _state => conversationId => {
    const conversation = _state.conversations.byId[conversationId];
    return conversation ? conversation.messages.length : 0;
  },
  getConversationById: (...getterArguments) => conversationId => {
    const [_state, , , _rootGetters] = getterArguments;
    const conversation = _state.conversations.byId[conversationId];
    if (!conversation) return undefined;

    const messageIds = conversation.messages;
    const messagesInConversation = messageIds.map(messageId => {
      const lastMessage = _rootGetters['message/messageById'](messageId);
      return lastMessage;
    });
    return {
      ...conversation,
      messages: messagesInConversation,
    };
  },
  unreadTextMessagesIn: (...getterArguments) => conversationId => {
    const [_state, _getters, , _rootGetters] = getterArguments;
    const conversation = _state.conversations.byId[conversationId];
    if (!conversation) return [];

    const messageIds = _state.conversations.byId[conversationId].messages;
    const messagesInConversation = messageIds.map(messageId =>
      _rootGetters['message/messageById'](messageId)
    );
    const { userLastSeenAt } = _getters.metaIn(conversationId);

    const messages = messagesInConversation.filter(message => {
      const { created_at: createdAt, message_type: messageType } = message;
      const isOutGoing = messageType === MESSAGE_TYPE.OUTGOING;
      const hasNotSeen = userLastSeenAt
        ? createdAt * 1000 > userLastSeenAt * 1000
        : true;
      return hasNotSeen && isOutGoing;
    });
    return messages;
  },
  unreadTextMessagesCountIn: (...getterArguments) => conversationId => {
    const [, _getters] = getterArguments;
    const unreadTextMessages = _getters.unreadTextMessagesIn(conversationId);

    return unreadTextMessages.length;
  },
  lastActiveConversationId: (...getterArguments) => {
    const [, _getters] = getterArguments;
    const conversations = _getters.allActiveConversations;
    const conversation = conversations[0];

    if (conversation) {
      return conversation.id;
    }
    return undefined;
  },
};
