import MessagePublicAPI from 'widget/api/messagePublic';
import { refreshActionCableConnector } from 'widget/helpers/actionCable';
import {
  createTemporaryMessage,
  createTemporaryAttachmentMessage,
} from './helpers';

export const actions = {
  sendMessage: async ({ commit }, params) => {
    try {
      commit(
        'conversationV2/setConversationUIFlag',
        { isCreating: true },
        { root: true }
      );
      const { content, conversationId } = params;
      const message = createTemporaryMessage({ content });
      const { id: echoId } = message;
      const messages = [message];
      commit('addMessagesEntry', { conversationId, messages });
      commit('addMessageIds', { conversationId, messages });
      await MessagePublicAPI.create(
        ...params,

        content,
        echoId
      );
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(
        'conversationV2/setConversationUIFlag',
        { isCreating: false },
        { root: true }
      );
    }
  },

  sendAttachment: async ({ commit }, params) => {
    try {
      commit(
        'conversationV2/setConversationUIFlag',
        { isCreating: true },
        { root: true }
      );
      const {
        attachment: { thumbUrl, fileType },
        conversationId,
      } = params;
      const message = createTemporaryAttachmentMessage({
        thumbUrl,
        fileType,
      });
      const messages = [message];
      const { id: echoId, ...rest } = message;
      commit('addMessagesEntry', { conversationId, messages });
      commit('addMessageIds', { conversationId, messages });
      const { data } = await MessagePublicAPI.create({
        echo_id: echoId,
        ...rest,
      });
      commit('updateAttachmentMessageStatus', {
        message: data,
        tempId: message.id,
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(
        'conversationV2/setConversationUIFlag',
        { isCreating: false },
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
      commit('setMessageUIFlag', { messageId, uiFlags: { isUpdating: false } });
    }
  },
};
