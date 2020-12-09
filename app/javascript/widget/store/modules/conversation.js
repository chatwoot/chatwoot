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

const groupConversationBySender = conversationsForADate =>
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
    allMessagesLoaded: false,
    isFetchingList: false,
    isAgentTyping: false,
  },
};

export const getters = {
  getAllMessagesLoaded: _state => _state.uiFlags.allMessagesLoaded,
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

  fetchOldConversations: async ({ commit }, { before } = {}) => {
    try {
      commit('setConversationListLoading', true);
      const { data } = await getMessagesAPI({ before });
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
