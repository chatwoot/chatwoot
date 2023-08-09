import MessageAPI from 'widget/api/message';
import { sendMessageAPI, sendAttachmentAPI } from 'widget/api/conversationV3';
// import { refreshActionCableConnector } from 'widget/helpers/actionCable';
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
        'conversationV3/removeMessageIdFromConversation',
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
      'conversationV3/appendMessageIdsToConversation',
      { conversationId, messages },
      { root: true }
    );
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
      commit('addMessagesEntry', { messages });
      commit('addMessageIds', { messages });
      commit(
        'conversationV3/appendMessageIdsToConversation',
        { conversationId, messages },
        { root: true }
      );
      // const { data: newMessage } = await MessagePublicAPI.create(
      //   conversationId,
      //   content,
      //   echoId
      // );

      const { data: newMessage } = await sendMessageAPI(content, echoId);

      dispatch('addOrUpdate', {
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
      const messages = [tempMessage];
      const attachmentParams = createAttachmentParams(params);

      commit('addMessagesEntry', { conversationId, messages });
      commit('addMessageIds', { conversationId, messages });
      commit(
        'conversationV3/appendMessageIdsToConversation',
        { conversationId, messages },
        { root: true }
      );

      // const { data } = await MessagePublicAPI.createAttachment(
      //   conversationId,
      //   attachmentParams
      // );
      const { data } = await sendAttachmentAPI(attachmentParams);
      dispatch('addOrUpdate', { ...data, echo_id: echoId });
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

      const {
        data: { contact: { pubsub_token: pubsubToken } = {} },
      } = await MessageAPI.update({
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
      // eslint-disable-next-line no-console
      console.log('pubsubToken', pubsubToken);
      // refreshActionCableConnector(pubsubToken);
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
