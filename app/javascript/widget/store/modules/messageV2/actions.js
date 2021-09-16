import MessagePublicAPI from 'widget/api/messagePublic';
import { refreshActionCableConnector } from '../../helpers/actionCable';
import {
  createTemporaryMessage,
  createTemporaryAttachmentMessage,
} from './helpers';

export const actions = {
  sendMessage: async ({ commit }, params) => {
    const {
      id: echoId,
      content,
      conversationId,
      inboxIdentifier,
      contactIdentifier,
    } = params;
    const message = createTemporaryMessage({ content });
    const messages = [message];
    commit('addMessagesEntry', { conversationId, messages });
    commit('addMessageIds', { conversationId, messages });
    await MessagePublicAPI.create(
      inboxIdentifier,
      contactIdentifier,
      conversationId,
      content,
      echoId
    );
  },

  sendAttachment: async ({ commit }, params) => {
    const {
      attachment: { thumbUrl, fileType },
      conversationId,
    } = params;
    const message = createTemporaryAttachmentMessage({
      thumbUrl,
      fileType,
    });
    const messages = [message];
    commit('addMessagesEntry', { conversationId, messages });
    commit('addMessageIds', { conversationId, messages });
    try {
      const { data } = await sendAttachmentAPI(params);
      commit('updateAttachmentMessageStatus', {
        message: data,
        tempId: message.id,
      });
    } catch (error) {
      // Show error
    }
  },
  update: async (
    { commit, dispatch },
    { email, messageId, submittedValues }
  ) => {
    commit('toggleUpdateStatus', true);
    try {
      const {
        data: { contact: { pubsub_token: pubsubToken } = {} },
      } = await MessageAPI.update({
        email,
        messageId,
        values: submittedValues,
      });
      commit(
        'conversation/updateMessage',
        {
          id: messageId,
          content_attributes: {
            submitted_email: email,
            submitted_values: email ? null : submittedValues,
          },
        },
        { root: true }
      );
      dispatch('contacts/get', {}, { root: true });
      refreshActionCableConnector(pubsubToken);
    } catch (error) {
      // Ignore error
    }
    commit('toggleUpdateStatus', false);
  },
};
