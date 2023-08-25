import { MESSAGE_TYPE } from 'widget/helpers/constants';
import { groupBy } from 'widget/helpers/utils';
import { groupConversationBySender } from 'widget/store/modules/conversationV3/helpers';
import { formatUnixDate } from 'shared/helpers/DateHelper';

import Conversation from 'widget/models/Conversation';
import ConversationMeta from 'widget/models/ConversationMeta';
import Message from 'widget/models/Message';

export const getters = {
  uiFlagsIn: () => conversationId => {
    return ConversationMeta.find(conversationId);
  },
  metaIn: () => conversationId => {
    const conversation = Conversation.find(conversationId);

    const { contact_last_seen_at: userLastSeenAt } = conversation;
    return {
      userLastSeenAt,
    };
  },
  isAllMessagesFetchedIn: () => conversationId => {
    const uiFlags = ConversationMeta.find(conversationId);
    return uiFlags.allFetched;
  },
  isCreating: _state => _state.uiFlags.isCreating,
  isAgentTypingIn: () => conversationId => {
    const uiFlags = ConversationMeta.find(conversationId);
    return uiFlags.isAgentTyping;
  },
  isFetchingConversationsList: _state => _state.uiFlags.isFetching,
  allConversations: () => Conversation.all(),
  allActiveConversations: () => {
    const conversations = Conversation.query()
      .with('messages')
      .where('status', 'open')
      .orderBy(conversation => conversation.messages[0].created_at, 'desc')
      .get();
    return conversations;
  },
  totalConversationsLength: () => Conversation.query().count(),
  firstMessageIn: () => conversationId => {
    const messages = Message.query()
      .where('conversation_id', conversationId)
      .get();

    if (messages.length) {
      return messages[0];
    }
    return undefined;
  },
  groupByMessagesIn: () => conversationId => {
    const messages = Message.query()
      .where('conversation_id', conversationId)
      .get();

    const messagesGroupedByDate = groupBy(messages, message =>
      formatUnixDate(message.created_at)
    );
    return Object.keys(messagesGroupedByDate).map(date => ({
      date,
      messages: groupConversationBySender(messagesGroupedByDate[date]),
    }));
  },
  isFetchingMessagesIn: () => conversationId => {
    const conversation = ConversationMeta.find(conversationId);
    return conversation ? conversation.isFetching : false;
  },
  allMessagesCountIn: () => conversationId => {
    return Message.query()
      .where('conversation_id', conversationId)
      .count();
  },
  getConversationById: () => conversationId => {
    return Conversation.find(conversationId).with('messages');
  },
  allMessagesIn: () => conversationId => {
    return Message.query()
      .where('conversation_id', conversationId)
      .get();
  },
  unreadTextMessagesIn: () => conversationId => {
    const { contact_last_seen_at: userLastSeenAt } = Conversation.find(
      conversationId
    );
    return Message.query()
      .where(message => {
        const { created_at: createdAt, message_type: messageType } = message;
        const isOutGoing = messageType === MESSAGE_TYPE.OUTGOING;
        const hasNotSeen = userLastSeenAt
          ? createdAt * 1000 > userLastSeenAt * 1000
          : true;
        return (
          conversationId === message.conversation_id && hasNotSeen && isOutGoing
        );
      })
      .get();
  },
  unreadTextMessagesCountIn: (...getterArguments) => conversationId => {
    const [, _getters] = getterArguments;
    const unreadTextMessages = _getters.unreadTextMessagesIn(conversationId);

    return unreadTextMessages.length;
  },
  lastActiveConversationId: () => {
    const conversation = Conversation.query().first();

    if (conversation) {
      return conversation.id;
    }
    return undefined;
  },
};
