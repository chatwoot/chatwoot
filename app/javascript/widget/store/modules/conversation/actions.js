import {
  createConversationAPI,
  sendMessageAPI,
  getMessagesAPI,
  sendAttachmentAPI,
  toggleTyping,
  setUserLastSeenAt,
  toggleStatus,
  setCustomAttributes,
  deleteCustomAttribute,
} from 'widget/api/conversation';

import { ON_CONVERSATION_CREATED } from 'widget/constants/widgetBusEvents';
import {
  createTemporaryMessage,
  getNonDeletedMessages,
  containsURL,
} from './helpers';
import { emitter } from 'shared/helpers/mitt';
import { event } from 'vue-gtag';

export const actions = {
  createConversation: async ({ commit, dispatch }, params) => {
    commit('setConversationUIFlag', { isCreating: true });
    try {
      const { data } = await createConversationAPI(params);
      const { messages } = data;
      const [message = {}] = messages;
      commit('pushMessageToConversation', message);
      dispatch('conversationAttributes/getAttributes', {}, { root: true });
      // Emit event to notify that conversation is created and show the chat screen
      emitter.emit(ON_CONVERSATION_CREATED);
    } catch (error) {
      // Ignore error
    } finally {
      commit('setConversationUIFlag', { isCreating: false });
    }
  },
  sendMessage: async ({ dispatch }, params) => {
    const { content, replyTo } = params;
    const message = createTemporaryMessage({ content, replyTo });
    dispatch('sendMessageWithData', message);
  },
  sendMessageWithData: async ({ commit, state }, message) => {
    const { id, content, replyTo, meta = {} } = message;

    commit('pushMessageToConversation', message);
    commit('updateMessageMeta', { id, meta: { ...meta, error: '' } });
    try {
      const { data } = await sendMessageAPI(content, replyTo);

      const payload = {
        message_length: data.content.length,
        campaign_id: state.activeCampaign?.id,
        contains_url: containsURL(data.content),
        conversation_id: data.conversation_id,
      };
      // TODO: remove console.log after verification
      console.log('chat_message_sent, text', payload);
      event('chat_message_sent', payload);

      // [VITE] Don't delete this manually, since `pushMessageToConversation` does the replacement for us anyway
      // commit('deleteMessage', message.id);
      commit('pushMessageToConversation', { ...data, status: 'sent' });
    } catch (error) {
      commit('pushMessageToConversation', { ...message, status: 'failed' });
      commit('updateMessageMeta', {
        id,
        meta: { ...meta, error: '' },
      });
    }
  },

  setLastMessageId: async ({ commit }) => {
    commit('setLastMessageId');
  },

  sendAttachment: async ({ commit, state }, params) => {
    const {
      attachment: { thumbUrl, fileType },
      meta = {},
    } = params;
    const attachment = {
      thumb_url: thumbUrl,
      data_url: thumbUrl,
      file_type: fileType,
      status: 'in_progress',
    };
    const tempMessage = createTemporaryMessage({
      attachments: [attachment],
      replyTo: params.replyTo,
    });
    commit('pushMessageToConversation', tempMessage);
    try {
      const { data } = await sendAttachmentAPI(params);

      const firstAttachment = data.attachments?.[0];
      const payload = {
        attachment: firstAttachment?.data_url,
        campaign_id: state.activeCampaign?.id,
        conversation_id: data.conversation_id,
      };
      // TODO: remove console.log after verification
      console.log('chat_message_sent, attachment', payload);
      event('chat_message_sent', payload);

      commit('updateAttachmentMessageStatus', {
        message: data,
        tempId: tempMessage.id,
      });
      commit('pushMessageToConversation', { ...data, status: 'sent' });
    } catch (error) {
      commit('pushMessageToConversation', { ...tempMessage, status: 'failed' });
      commit('updateMessageMeta', {
        id: tempMessage.id,
        meta: { ...meta, error: '' },
      });
      // Show error
    }
  },
  fetchOldConversations: async ({ commit }, { before } = {}) => {
    try {
      commit('setConversationListLoading', true);
      const {
        data: { payload, meta },
      } = await getMessagesAPI({ before });
      const { contact_last_seen_at: lastSeen } = meta;
      const formattedMessages = getNonDeletedMessages({ messages: payload });
      commit('conversation/setMetaUserLastSeenAt', lastSeen, { root: true });
      commit('setMessagesInConversation', formattedMessages);
      commit('setConversationListLoading', false);
    } catch (error) {
      commit('setConversationListLoading', false);
    }
  },

  syncLatestMessages: async ({ state, commit }) => {
    try {
      const { lastMessageId, conversations } = state;

      const {
        data: { payload, meta },
      } = await getMessagesAPI({ after: lastMessageId });

      const { contact_last_seen_at: lastSeen } = meta;
      const formattedMessages = getNonDeletedMessages({ messages: payload });
      const missingMessages = formattedMessages.filter(
        message => conversations?.[message.id] === undefined
      );
      if (!missingMessages.length) return;
      missingMessages.forEach(message => {
        conversations[message.id] = message;
      });
      // Sort conversation messages by created_at
      const updatedConversation = Object.fromEntries(
        Object.entries(conversations).sort(
          (a, b) => a[1].created_at - b[1].created_at
        )
      );
      commit('conversation/setMetaUserLastSeenAt', lastSeen, { root: true });
      commit('setMissingMessagesInConversation', updatedConversation);
    } catch (error) {
      // IgnoreError
    }
  },

  clearConversations: ({ commit }) => {
    commit('clearConversations');
  },

  addOrUpdateMessage: async ({ commit }, data) => {
    const { id, content_attributes } = data;
    if (content_attributes && content_attributes.deleted) {
      commit('deleteMessage', id);
      return;
    }
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

  resolveConversation: async () => {
    await toggleStatus();
  },

  setCustomAttributes: async (_, customAttributes = {}) => {
    try {
      await setCustomAttributes(customAttributes);
    } catch (error) {
      // IgnoreError
    }
  },

  deleteCustomAttribute: async (_, customAttribute) => {
    try {
      await deleteCustomAttribute(customAttribute);
    } catch (error) {
      // IgnoreError
    }
  },
};
