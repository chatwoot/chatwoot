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
        'conversationV2/removeMessageIdFromConversation',
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
      'conversationV2/appendMessageIdsToConversation',
      { conversationId, messages },
      { root: true }
    );
  },
  sendMessage: async ({ commit, dispatch }, params) => {
    const { content, conversationId } = params;
    try {
      commit(
        'conversationV2/setConversationUIFlag',
        { uiFlags: { isCreating: true }, conversationId },
        { root: true }
      );

      const message = createTemporaryMessage({ content });
      const { id: echoId } = message;
      const messages = [message];
      commit('addMessagesEntry', { messages });
      commit('addMessageIds', { messages });
      commit(
        'conversationV2/appendMessageIdsToConversation',
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
        'conversationV2/setConversationUIFlag',
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
        'conversationV2/setConversationUIFlag',
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
        'conversationV2/appendMessageIdsToConversation',
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
        'conversationV2/setConversationUIFlag',
        { uiFlags: { isCreating: false }, conversationId },
        { root: true }
      );
    }
  },

  updateMessage: async (
    { commit, dispatch },
    { email, messageId, submittedValues }
  ) => {
    try {
      commit('setMessageUIFlag', {
        messageId,
        uiFlags: { isUpdating: true },
      });
      const {
        data: { contact: { pubsub_token: pubsubToken } = {} },
      } = await MessagePublicAPI.update({
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
      dispatch('contacts/get', {}, { root: true });
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
