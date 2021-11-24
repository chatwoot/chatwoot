import MessagePublicAPI from 'widget/api/messagePublic';
import { refreshActionCableConnector } from 'widget/helpers/actionCable';
import {
  createTemporaryMessage,
  createTemporaryAttachmentMessage,
  createAttachmentParams,
} from './helpers';

export const actions = {
  addOrUpdate: async ({ commit, getters }, message) => {
    const {
      conversation_id: conversationId,
      id: messageId,
      echo_id: echoId,
    } = message;

    const messageIdInStore = echoId || messageId;
    const doesMessageExist = getters.messageById(messageIdInStore);

    if (doesMessageExist) {
      commit(
        'conversation/removeMessageIdFromConversation',
        { conversationId, messageId: echoId },
        { root: true }
      );
      commit('removeMessageEntry', echoId);
      commit('removeMessageId', echoId);
    }
    const messages = [message];
    commit('addMessagesEntry', { conversationId, messages });
    commit('addMessageIds', { messages });
    commit(
      'conversation/appendMessageIdsToConversation',
      { conversationId, messages },
      { root: true }
    );
  },
  sendMessage: async ({ commit, dispatch }, params) => {
    const { content, conversationId } = params;
    try {
      commit(
        'conversation/setConversationUIFlag',
        { uiFlags: { isCreating: true }, conversationId },
        { root: true }
      );

      const message = createTemporaryMessage({ content });
      const { id: echoId } = message;
      const messages = [message];
      commit('addMessagesEntry', { messages });
      commit('addMessageIds', { messages });
      commit(
        'conversation/appendMessageIdsToConversation',
        { conversationId, messages },
        { root: true }
      );
      const { data: newMessage } = await MessagePublicAPI.create(
        conversationId,
        content,
        echoId
      );

      dispatch('addOrUpdate', {
        ...newMessage,
        echo_id: echoId,
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(
        'conversation/setConversationUIFlag',
        { uiFlags: { isCreating: false }, conversationId },
        { root: true }
      );
    }
  },

  sendAttachment: async ({ commit, dispatch }, params) => {
    const {
      attachment: { thumbUrl, fileType },
      conversationId,
    } = params;
    try {
      commit(
        'conversation/setConversationUIFlag',
        { uiFlags: { isCreating: true }, conversationId },
        { root: true }
      );

      const tempMessage = createTemporaryAttachmentMessage({
        thumbUrl,
        fileType,
      });

      const { id: echoId } = tempMessage;
      const messages = [tempMessage];
      const attachmentParams = createAttachmentParams(params);

      commit('addMessagesEntry', { conversationId, messages });
      commit('addMessageIds', { conversationId, messages });
      commit(
        'conversation/appendMessageIdsToConversation',
        { conversationId, messages },
        { root: true }
      );

      const { data } = await MessagePublicAPI.createAttachment(
        conversationId,
        attachmentParams
      );
      dispatch('addOrUpdate', { ...data, echo_id: echoId });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(
        'conversation/setConversationUIFlag',
        { uiFlags: { isCreating: false }, conversationId },
        { root: true }
      );
    }
  },

  update: async ({ commit, getters, dispatch }, params) => {
    const { email, messageId, submittedValues } = params;
    try {
      commit('setMessageUIFlag', {
        messageId,
        uiFlags: { isUpdating: true },
      });

      const { conversation_id: conversationId } = getters.messageById(
        messageId
      );
      const {
        data: { contact: { pubsub_token: pubsubToken } = {} },
      } = await MessagePublicAPI.update(conversationId, {
        email,
        id: messageId,
        submitted_values: submittedValues,
      });

      commit('updateMessageEntry', {
        id: messageId,
        content_attributes: {
          submitted_email: email,
          submitted_values: email ? null : submittedValues,
        },
      });
      dispatch('contact/get', {}, { root: true });
      refreshActionCableConnector(pubsubToken);
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
