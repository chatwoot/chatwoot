/* eslint-disable no-param-reassign */
import Vue from 'vue';
import {
  sendMessageAPI,
  getConversationAPI,
  sendAttachmentAPI,
  toggleTyping,
} from 'widget/api/conversation';
import { MESSAGE_TYPE } from 'widget/helpers/constants';
import { playNotificationAudio } from 'shared/helpers/AudioNotificationHelper';
import getUuid from '../../helpers/uuid';
import DateHelper from '../../../shared/helpers/DateHelper';

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

export const findUndeliveredMessage = (messageInbox, { content }) =>
  Object.values(messageInbox).filter(
    message => message.content === content && message.status === 'in_progress'
  );

export const DEFAULT_CONVERSATION = 'default';

const state = {
  conversations: {},
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
      message => new DateHelper(message.created_at).format()
    );
    return Object.keys(conversationGroupedByDate).map(date => {
      const messages = conversationGroupedByDate[date].map((message, index) => {
        let showAvatar = false;
        if (index === conversationGroupedByDate[date].length - 1) {
          showAvatar = true;
        } else {
          const nextMessage = conversationGroupedByDate[date][index + 1];
          const currentSender = message.sender ? message.sender.name : '';
          const nextSender = nextMessage.sender ? nextMessage.sender.name : '';
          showAvatar =
            currentSender !== nextSender ||
            message.message_type !== nextMessage.message_type;
        }
        return { showAvatar, ...message };
      });

      return {
        date,
        messages,
      };
    });
  },
  getIsFetchingList: _state => _state.uiFlags.isFetchingList,
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
    const tempMessage = createTemporaryMessage({ attachments: [attachment] });
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
      const { data } = await getConversationAPI({ before });
      commit('setMessagesInConversation', data);
      commit('setConversationListLoading', false);
    } catch (error) {
      commit('setConversationListLoading', false);
    }
  },

  addMessage({ commit }, data) {
    if (data.message_type === MESSAGE_TYPE.OUTGOING) {
      playNotificationAudio();
    }

    commit('pushMessageToConversation', data);
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
      // console error
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
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
