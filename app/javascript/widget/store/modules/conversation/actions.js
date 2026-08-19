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
  belongsToThread,
  createTemporaryMessage,
  getNonDeletedMessages,
} from './helpers';
import { emitter } from 'shared/helpers/mitt';

const newestThreadId = messages =>
  messages.reduce(
    (latest, item) => Math.max(latest, item.conversation_id || 0),
    0
  );

// The server answers on a new thread once the current one is resolved and replies are off.
// Messages and attributes go stale independently, so either one triggers the refresh.
const resetStaleThread = async (
  { commit, dispatch, state, rootState },
  conversationId
) => {
  const staleMessages = () =>
    Object.values(state.conversations).filter(
      item => item.conversation_id && item.conversation_id < conversationId
    );
  const { id: attributeId } = rootState.conversationAttributes;
  const hasStaleAttributes = attributeId && attributeId < conversationId;
  if (!staleMessages().length && !hasStaleAttributes) return;

  // Recorded before anything is awaited, so responses that outlive the switch are rejected by
  // the store instead of merging the thread being left back into the new one.
  commit('setThreadId', conversationId);
  await dispatch('conversationAttributes/getAttributes', {}, { root: true });
  // Dropped after the refresh, or the socket adds the old thread's events straight back.
  staleMessages().forEach(item => commit('deleteMessage', item.id));
  // Paging to the start of the old thread leaves this set, blocking scroll back in the new one.
  commit('setConversationUIFlag', { allMessagesLoaded: false });
  dispatch('fetchOldConversations');
};

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
    { commit, dispatch, state: conversationState, rootState },
    { message, pendingCustomAttributes = {}, pendingLabels = [] }
  ) => {
    const { id, content, replyTo, meta = {} } = message;
    const hasPendingMetadata =
      Object.keys(pendingCustomAttributes).length > 0 ||
      pendingLabels.length > 0;

    // Only `in_progress` messages are replaced by the server copy; a retry still carries `failed`.
    commit('pushMessageToConversation', { ...message, status: 'in_progress' });
    commit('updateMessageMeta', { id, meta: { ...meta, error: '' } });
    try {
      const { data } = await sendMessageAPI(content, replyTo, {
        customAttributes: hasPendingMetadata
          ? pendingCustomAttributes
          : undefined,
        labels: hasPendingMetadata ? pendingLabels : undefined,
      });
      if (hasPendingMetadata) {
        commit('clearPendingConversationMetadata');
      }

      const { conversation_id: threadId } = data;
      // Only an older thread is rejected: a newer one is the server moving us, which is the switch
      // itself. The store would drop this reply anyway, so its placeholder goes with it.
      if (conversationState.threadId && threadId < conversationState.threadId) {
        commit('deleteMessage', id);
        return;
      }

      resetStaleThread(
        { commit, dispatch, state: conversationState, rootState },
        threadId
      );

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

  sendAttachment: async (
    { commit, dispatch, state: conversationState, rootState },
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

    commit('pushMessageToConversation', tempMessage);
    try {
      const { data } = await sendAttachmentAPI(params, {
        customAttributes: hasPendingMetadata
          ? pendingCustomAttributes
          : undefined,
        labels: hasPendingMetadata ? pendingLabels : undefined,
      });
      if (hasPendingMetadata) {
        commit('clearPendingConversationMetadata');
      }
      const { conversation_id: threadId } = data;
      if (conversationState.threadId && threadId < conversationState.threadId) {
        commit('deleteMessage', tempMessage.id);
        return;
      }

      resetStaleThread(
        { commit, dispatch, state: conversationState, rootState },
        threadId
      );

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
  fetchOldConversations: async (store, { before } = {}) => {
    const { commit, state } = store;
    // An empty page marks the thread fully loaded, so a page for a thread we have left must not
    // reach the store at all — the message filter alone cannot tell those two apart.
    const requestedThread = state.threadId;
    try {
      commit('setConversationListLoading', true);
      const {
        data: { payload, meta },
      } = await getMessagesAPI({ before });
      if (state.threadId !== requestedThread) return;

      const { contact_last_seen_at: lastSeen } = meta;
      const formattedMessages = getNonDeletedMessages({ messages: payload });
      // The server only serves its newest conversation, so a payload can be the first sign that
      // the thread moved while this session could not observe it. Same flow as every other sign.
      resetStaleThread(store, newestThreadId(formattedMessages));
      commit('conversation/setMetaUserLastSeenAt', lastSeen, { root: true });
      commit('setMessagesInConversation', formattedMessages);
    } catch (error) {
      // Ignore error
    } finally {
      commit('setConversationListLoading', false);
    }
  },

  syncLatestMessages: async store => {
    const { state, commit } = store;
    try {
      const { lastMessageId, conversations } = state;

      const {
        data: { payload, meta },
      } = await getMessagesAPI({ after: lastMessageId });

      const { contact_last_seen_at: lastSeen } = meta;
      const formattedMessages = getNonDeletedMessages({ messages: payload });
      // A reconnect sync is how a session that was offline learns the thread moved.
      resetStaleThread(store, newestThreadId(formattedMessages));
      const missingMessages = formattedMessages.filter(
        message =>
          conversations?.[message.id] === undefined &&
          belongsToThread(state.threadId, message)
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

  addOrUpdateMessage: async (store, data) => {
    const { id, content_attributes, conversation_id: threadId } = data;
    if (content_attributes && content_attributes.deleted) {
      store.commit('deleteMessage', id);
      return;
    }
    // Another session can move the visitor to a new thread, and its first message arriving over
    // the socket is how this session finds out — so it takes the same switch flow as a send.
    if (threadId) resetStaleThread(store, threadId);
    store.commit('pushMessageToConversation', data);
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
