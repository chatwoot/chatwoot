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
  hasLeftConversation,
} from './helpers';
import { emitter } from 'shared/helpers/mitt';
import { isMultipleConversationsEnabled } from 'widget/helpers/utils';

// A new thread has no id until its first message creates the conversation, so messages sent
// meanwhile from the same thread wait for that request and post to the conversation it created.
let pendingCreation = null;

const postToThread = ({ commit, rootState }, post) => {
  const { conversationAttributes, conversationList } = rootState;
  if (!isMultipleConversationsEnabled() || conversationAttributes.id) {
    return post();
  }
  if (pendingCreation?.thread === conversationList.thread) {
    return pendingCreation.request.then(({ data }) =>
      post(data.conversation_id)
    );
  }
  const creation = { thread: conversationList.thread, request: post() };
  pendingCreation = creation;
  commit('setConversationUIFlag', { isCreating: true });
  const clear = () => {
    if (pendingCreation !== creation) return;
    pendingCreation = null;
    commit('setConversationUIFlag', { isCreating: false });
  };
  creation.request.then(clear, clear);
  return creation.request;
};

export const actions = {
  createConversation: async ({ commit, dispatch, rootState }, params) => {
    const { thread } = rootState.conversationList;
    commit('setConversationUIFlag', { isCreating: true });
    try {
      const { data } = await createConversationAPI(params);
      if (hasLeftConversation(rootState, thread)) return;
      const { messages } = data;
      const [message = {}] = messages;
      commit('pushMessageToConversation', message);
      if (isMultipleConversationsEnabled()) {
        dispatch('conversationList/attach', data.id, { root: true });
      } else {
        dispatch('conversationAttributes/getAttributes', {}, { root: true });
      }
      // Emit event to notify that conversation is created and show the chat screen
      emitter.emit(ON_CONVERSATION_CREATED);
    } catch (error) {
      // Ignore error
    } finally {
      // Leaving the thread already reset it; another thread may be creating by now.
      if (!hasLeftConversation(rootState, thread)) {
        commit('setConversationUIFlag', { isCreating: false });
      }
    }
  },
  sendMessage: async ({ dispatch, state: conversationState }, params) => {
    const { content, replyTo } = params;
    const message = createTemporaryMessage({ content, replyTo });
    const { pendingCustomAttributes, pendingLabels } = conversationState;
    dispatch('sendMessageWithData', {
      message,
      pendingCustomAttributes,
      pendingLabels,
    });
  },
  sendMessageWithData: async (
    { commit, dispatch, rootState },
    { message, pendingCustomAttributes = {}, pendingLabels = [] }
  ) => {
    const { id, content, replyTo, meta = {} } = message;
    const hasPendingMetadata =
      Object.keys(pendingCustomAttributes).length > 0 ||
      pendingLabels.length > 0;
    const { thread } = rootState.conversationList;

    // A retried message arrives marked failed; in progress again, the sent copy replaces it.
    commit('pushMessageToConversation', { ...message, status: 'in_progress' });
    commit('updateMessageMeta', { id, meta: { ...meta, error: '' } });
    try {
      const { data } = await postToThread(
        { commit, rootState },
        conversationId =>
          sendMessageAPI(content, replyTo, {
            customAttributes: hasPendingMetadata
              ? pendingCustomAttributes
              : undefined,
            labels: hasPendingMetadata ? pendingLabels : undefined,
            conversationId,
          })
      );
      if (hasLeftConversation(rootState, thread)) {
        commit('deleteMessage', id);
        return;
      }
      if (hasPendingMetadata) {
        commit('clearPendingConversationMetadata');
      }

      // [VITE] Don't delete this manually, since `pushMessageToConversation` does the replacement for us anyway
      // commit('deleteMessage', message.id);
      commit('pushMessageToConversation', { ...data, status: 'sent' });
      if (
        isMultipleConversationsEnabled() &&
        !rootState.conversationAttributes.id
      ) {
        dispatch('conversationList/attach', data.conversation_id, {
          root: true,
        });
      }
    } catch (error) {
      if (hasLeftConversation(rootState, thread)) {
        commit('deleteMessage', id);
        return;
      }
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

  sendAttachment: async (
    { commit, dispatch, rootState, state: conversationState },
    params
  ) => {
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
    const { pendingCustomAttributes, pendingLabels } = conversationState;
    const hasPendingMetadata =
      Object.keys(pendingCustomAttributes).length > 0 ||
      pendingLabels.length > 0;
    const { thread } = rootState.conversationList;

    commit('pushMessageToConversation', tempMessage);
    try {
      const { data } = await postToThread(
        { commit, rootState },
        conversationId =>
          sendAttachmentAPI(params, {
            customAttributes: hasPendingMetadata
              ? pendingCustomAttributes
              : undefined,
            labels: hasPendingMetadata ? pendingLabels : undefined,
            conversationId,
          })
      );
      if (hasLeftConversation(rootState, thread)) {
        commit('deleteMessage', tempMessage.id);
        return;
      }
      if (hasPendingMetadata) {
        commit('clearPendingConversationMetadata');
      }
      commit('updateAttachmentMessageStatus', {
        message: data,
        tempId: tempMessage.id,
      });
      commit('pushMessageToConversation', { ...data, status: 'sent' });
      if (
        isMultipleConversationsEnabled() &&
        !rootState.conversationAttributes.id
      ) {
        dispatch('conversationList/attach', data.conversation_id, {
          root: true,
        });
      }
    } catch (error) {
      if (hasLeftConversation(rootState, thread)) {
        commit('deleteMessage', tempMessage.id);
        return;
      }
      commit('pushMessageToConversation', { ...tempMessage, status: 'failed' });
      commit('updateMessageMeta', {
        id: tempMessage.id,
        meta: { ...meta, error: '' },
      });
      // Show error
    }
  },
  fetchOldConversations: async ({ commit, rootState }, { before } = {}) => {
    const { thread } = rootState.conversationList;
    try {
      commit('setConversationListLoading', true);
      const {
        data: { payload, meta },
      } = await getMessagesAPI({ before });
      if (hasLeftConversation(rootState, thread)) return;
      const { contact_last_seen_at: lastSeen } = meta;
      const formattedMessages = getNonDeletedMessages({ messages: payload });
      commit('conversation/setMetaUserLastSeenAt', lastSeen, { root: true });
      commit('setMessagesInConversation', formattedMessages);
    } catch (error) {
      // Ignore error
    } finally {
      commit('setConversationListLoading', false);
    }
  },

  syncLatestMessages: async ({ state, commit, rootState }) => {
    const { thread } = rootState.conversationList;
    try {
      const { lastMessageId, conversations } = state;

      const {
        data: { payload, meta },
      } = await getMessagesAPI({ after: lastMessageId });
      if (hasLeftConversation(rootState, thread)) return;

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

  setUserLastSeen: async ({ commit, getters: appGetters, rootState }) => {
    if (!appGetters.getConversationSize) {
      return;
    }

    const lastSeen = Date.now() / 1000;
    try {
      commit('setMetaUserLastSeenAt', lastSeen);
      commit('conversationList/markRead', rootState.conversationAttributes.id, {
        root: true,
      });
      await setUserLastSeenAt({ lastSeen });
    } catch (error) {
      // IgnoreError
    }
  },

  resolveConversation: async () => {
    await toggleStatus();
  },

  setCustomAttributes: async (
    { commit, rootGetters },
    customAttributes = {}
  ) => {
    if (!rootGetters['conversationAttributes/getConversationParams']?.id) {
      commit('setPendingCustomAttributes', customAttributes);
      return;
    }
    try {
      await setCustomAttributes(customAttributes);
    } catch (error) {
      // IgnoreError
    }
  },

  deleteCustomAttribute: async ({ commit, rootGetters }, customAttribute) => {
    if (!rootGetters['conversationAttributes/getConversationParams']?.id) {
      commit('removePendingCustomAttribute', customAttribute);
      return;
    }
    try {
      await deleteCustomAttribute(customAttribute);
    } catch (error) {
      // IgnoreError
    }
  },
};
