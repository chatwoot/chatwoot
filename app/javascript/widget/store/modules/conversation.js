/* eslint-disable no-param-reassign */
import Vue from 'vue';
import {
  sendMessageAPI,
  getMessagesAPI,
  sendAttachmentAPI,
  toggleTyping,
  setUserLastSeenAt,
} from 'widget/api/conversation';
import { MESSAGE_TYPE } from 'widget/helpers/constants';
import { playNotificationAudio } from 'shared/helpers/AudioNotificationHelper';
import { formatUnixDate } from 'shared/helpers/DateHelper';
import { isASubmittedFormMessage } from 'shared/helpers/MessageTypeHelper';

import getUuid from '../../helpers/uuid';
const groupBy = require('lodash.groupby');

export const createTemporaryMessage = ({ attachments, content }) => {
  const timestamp = new Date().getTime() / 1000;
  return {
    id: getUuid(),
    content,
    attachments,
    status: 'in_progress',
    created_at: timestamp,
    message_type: MESSAGE_TYPE.INCOMING,
  };
};

const getSenderName = message => (message.sender ? message.sender.name : '');

const shouldShowAvatar = (message, nextMessage) => {
  const currentSender = getSenderName(message);
  const nextSender = getSenderName(nextMessage);

  return (
    currentSender !== nextSender ||
    message.message_type !== nextMessage.message_type ||
    isASubmittedFormMessage(nextMessage)
  );
};

const groupMessagesBySender = conversationsForADate =>
  conversationsForADate.map((message, index) => {
    let showAvatar = false;
    const isLastMessage = index === conversationsForADate.length - 1;
    if (isASubmittedFormMessage(message)) {
      showAvatar = false;
    } else if (isLastMessage) {
      showAvatar = true;
    } else {
      const nextMessage = conversationsForADate[index + 1];
      showAvatar = shouldShowAvatar(message, nextMessage);
    }
    return { showAvatar, ...message };
  });

export const findUndeliveredMessage = (messageInbox, { content }) =>
  Object.values(messageInbox).filter(
    message => message.content === content && message.status === 'in_progress'
  );

export const onNewMessageCreated = data => {
  const { message_type: messageType } = data;
  const isIncomingMessage = messageType === MESSAGE_TYPE.OUTGOING;

  if (isIncomingMessage) {
    playNotificationAudio();
  }
};

export const DEFAULT_CONVERSATION = 'default';

const state = {
  conversations: {},
  meta: {
    userLastSeenAt: undefined,
  },
  uiFlags: {
    allMessagesLoaded: {},
    isFetchingList: {},
    isAgentTyping: {},
  },
};

export const getters = {
  getAllMessagesLoaded: _state => id => _state.uiFlags.allMessagesLoaded[id],
  getIsAgentTyping: _state => id => _state.uiFlags.isAgentTyping[id],
  getConversationSize: (_, messageGetters) => id => {
    const messages = messageGetters.getMessages(id);
    return messages.length;
  },

  getEarliestMessage: (_state, messageGetters) => id => {
    const messages = messageGetters.getMessages(id);
    if (messages.length) {
      return messages[0];
    }
    return {};
  },
  getMessages: ({ conversations }) => conversationId => {
    return Object.values(conversations)
      .filter(
        conversation =>
          Number(conversation.conversation_id) === Number(conversationId)
      )
      .sort((a, b) => a.id - b.id);
  },
  getGroupedConversation: (_state, messageGetters) => id => {
    const messages = messageGetters.getMessages(id);
    const messagesGroupedByDate = groupBy(messages, message =>
      formatUnixDate(message.created_at)
    );
    return Object.keys(messagesGroupedByDate).map(date => ({
      date,
      messages: groupMessagesBySender(messagesGroupedByDate[date]),
    }));
  },
  getIsFetchingList: _state => id => _state.uiFlags.isFetchingList[id],
};

export const actions = {
  sendMessage: async ({ commit }, params) => {
    const { content } = params;
    commit('pushMessageToConversation', createTemporaryMessage({ content }));
    await sendMessageAPI(content);
  },

  sendAttachment: async ({ commit }, params) => {
    const {
      attachment: { thumbUrl, fileType },
    } = params;
    const attachment = {
      thumb_url: thumbUrl,
      data_url: thumbUrl,
      file_type: fileType,
      status: 'in_progress',
    };
    const tempMessage = createTemporaryMessage({
      attachments: [attachment],
    });
    commit('pushMessageToConversation', tempMessage);
    try {
      const { data } = await sendAttachmentAPI(params);
      commit('updateAttachmentMessageStatus', {
        message: data,
        tempId: tempMessage.id,
      });
    } catch (error) {
      // Show error
    }
  },

  fetchOldMessages: async ({ commit }, { before, conversationId } = {}) => {
    try {
      commit('setConversationListLoading', true);
      const { data } = await getMessagesAPI({ before, conversationId });
      commit('setMessagesInConversation', data);
      commit('setConversationListLoading', false);
    } catch (error) {
      commit('setConversationListLoading', false);
    }
  },

  addMessage: async ({ commit }, data) => {
    commit('pushMessageToConversation', data);
    onNewMessageCreated(data);
  },

  updateMessage({ commit }, data) {
    commit('pushMessageToConversation', data);
  },

  toggleAgentTyping({ commit }, data) {
    commit('toggleAgentTypingStatus', data);
  },

  toggleUserTyping: async (_, data) => {
    try {
      await toggleTyping(data);
    } catch (error) {
      // IgnoreError
    }
  },

  setUserLastSeen: async ({ commit, getters: appGetters }) => {
    if (!appGetters.getConversationSize) {
      return;
    }

    const lastSeen = Date.now() / 1000;
    try {
      commit('setMetaUserLastSeenAt', lastSeen);
      await setUserLastSeenAt({ lastSeen });
    } catch (error) {
      // IgnoreError
    }
  },
};

export const mutations = {
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

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
