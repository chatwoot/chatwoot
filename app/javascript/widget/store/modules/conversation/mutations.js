import Vue from 'vue';
import { MESSAGE_TYPE } from 'widget/helpers/constants';
import { findUndeliveredMessage } from './helpers';

export const mutations = {
  clearConversations($state) {
    Vue.set($state, 'conversations', {});
  },
  pushMessageToConversation($state, message) {
    const { id, status, message_type: type } = message;
    const messagesInbox = $state.conversations;
    const isMessageIncoming = type === MESSAGE_TYPE.INCOMING;
    const isTemporaryMessage = status === 'in_progress';

    if (!isMessageIncoming || isTemporaryMessage) {
      Vue.set(messagesInbox, id, message);
      return;
    }

    const [messageInConversation] = findUndeliveredMessage(
      messagesInbox,
      message
    );
    if (!messageInConversation) {
      Vue.set(messagesInbox, id, message);
    } else {
      Vue.delete(messagesInbox, messageInConversation.id);
      Vue.set(messagesInbox, id, message);
    }
  },

  updateAttachmentMessageStatus($state, { message, tempId }) {
    const { id } = message;
    const messagesInbox = $state.conversations;

    const messageInConversation = messagesInbox[tempId];

    if (messageInConversation) {
      Vue.delete(messagesInbox, tempId);
      Vue.set(messagesInbox, id, { ...message });
    }
  },

  setConversationListLoading($state, status) {
    $state.uiFlags.isFetchingList = status;
  },

  setMessagesInConversation($state, payload) {
    if (!payload.length) {
      $state.uiFlags.allMessagesLoaded = true;
      return;
    }

    payload.map(message => Vue.set($state.conversations, message.id, message));
  },

  updateMessage($state, { id, content_attributes }) {
    $state.conversations[id] = {
      ...$state.conversations[id],
      content_attributes: {
        ...($state.conversations[id].content_attributes || {}),
        ...content_attributes,
      },
    };
  },

  toggleAgentTypingStatus($state, { status }) {
    const isTyping = status === 'on';
    $state.uiFlags.isAgentTyping = isTyping;
  },

  setMetaUserLastSeenAt($state, lastSeen) {
    $state.meta.userLastSeenAt = lastSeen;
  },
};
