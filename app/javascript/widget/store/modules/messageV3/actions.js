import MessageV3API from 'widget/api/messageV3';

import {
  createTemporaryMessage,
  createTemporaryAttachmentMessage,
  createAttachmentParams,
} from './helpers';

export const actions = {
  appendMessages: async ({ commit }, { conversationId, messages }) => {
    commit('addMessagesEntry', { conversationId, messages });
    commit('addMessageIds', { messages });
    commit(
      'conversationV3/appendMessageIdsToConversation',
      { conversationId, messages },
      { root: true }
    );
  },
  updateTempMessage: async ({ commit, getters, dispatch }, message) => {
    const {
      conversation_id: conversationId,
      id: messageId,
      echo_id: echoId,
    } = message;

    const doesMessageExist = getters.messageById(echoId);
    if (doesMessageExist) {
      dispatch('appendMessages', { conversationId, messages: [message] });
      commit(
        'conversationV3/updateMessageIdInConversation',
        { conversationId, messageId, echoId },
        { root: true }
      );
      commit('removeMessageEntry', echoId);
      commit('removeMessageId', echoId);
    }
  },
  sendMessageIn: async ({ commit, dispatch }, params) => {
    const { content, conversationId } = params;
    try {
      commit(
        'conversationV3/setConversationUIFlag',
        { uiFlags: { isCreating: true }, conversationId },
        { root: true }
      );

      const message = createTemporaryMessage({ content });
      const { id: echoId } = message;
      const messages = [message];
      dispatch('appendMessages', { conversationId, messages });

      const { data: newMessage } = await MessageV3API.create(content, echoId);
      dispatch('updateTempMessage', {
        ...newMessage,
        echo_id: echoId,
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(
        'conversationV3/setConversationUIFlag',
        { uiFlags: { isCreating: false }, conversationId },
        { root: true }
      );
    }
  },

  sendAttachmentIn: async ({ commit, dispatch }, params) => {
    const {
      attachment: { thumbUrl, fileType },
      conversationId,
    } = params;
    try {
      commit(
        'conversationV3/setConversationUIFlag',
        { uiFlags: { isCreating: true }, conversationId },
        { root: true }
      );

      const tempMessage = createTemporaryAttachmentMessage({
        thumbUrl,
        fileType,
      });

      const { id: echoId } = tempMessage;
      const attachmentParams = createAttachmentParams(params);
      const messages = [tempMessage];
      dispatch('appendMessages', { conversationId, messages });

      const { data } = await MessageV3API.createAttachment(attachmentParams);
      dispatch('updateTempMessage', { ...data, echo_id: echoId });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(
        'conversationV3/setConversationUIFlag',
        { uiFlags: { isCreating: false }, conversationId },
        { root: true }
      );
    }
  },

  update: async ({ commit, dispatch }, params) => {
    const { email, messageId, submittedValues } = params;
    try {
      commit('setMessageUIFlag', {
        messageId,
        uiFlags: { isUpdating: true },
      });

      await MessageV3API.update({
        email,
        messageId,
        values: submittedValues,
      });
      commit('updateMessageEntry', {
        id: messageId,
        content_attributes: {
          submitted_email: email,
          submitted_values: email ? null : submittedValues,
        },
      });
      dispatch('contact/get', {}, { root: true });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setMessageUIFlag', {
        messageId,
        uiFlags: { isUpdating: false },
      });
    }
  },
};
