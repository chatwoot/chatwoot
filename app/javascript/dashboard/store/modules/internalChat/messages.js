import InternalChatMessagesAPI from '../../../api/internalChatMessages';
import { throwErrorMessage } from 'dashboard/store/utils/api';

const initialState = () => ({
  records: {},
  threadReplies: {},
  uiFlags: {
    isFetching: false,
    isSending: false,
  },
});

const state = initialState();

const getters = {
  getMessages: _state => channelId => {
    return _state.records[channelId] || [];
  },

  getMessageById: _state => (channelId, messageId) => {
    const messages = _state.records[channelId] || [];
    return messages.find(m => m.id === messageId) || null;
  },

  getThreadReplies: _state => parentMessageId => {
    return _state.threadReplies[parentMessageId] || [];
  },

  getUIFlags: _state => {
    return _state.uiFlags;
  },
};

const actions = {
  fetchMessages: async ({ commit }, { channelId, params = {} }) => {
    commit('SET_UI_FLAG', { isFetching: true });
    try {
      const response = await InternalChatMessagesAPI.getMessages(
        channelId,
        params
      );
      const messages = response.data.messages || response.data;
      if (params.around) {
        commit('SET_MESSAGES', { channelId, messages });
      } else if (params.before) {
        commit('PREPEND_MESSAGES', { channelId, messages });
      } else if (params.after) {
        commit('APPEND_MESSAGES', { channelId, messages });
      } else {
        commit('SET_MESSAGES', { channelId, messages });
      }
      return messages;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isFetching: false });
    }
  },

  sendMessage: async ({ commit }, { channelId, data, files = [] }) => {
    commit('SET_UI_FLAG', { isSending: true });
    try {
      const response = await InternalChatMessagesAPI.createMessage(
        channelId,
        data,
        files
      );
      commit('ADD_MESSAGE', { channelId, message: response.data });
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isSending: false });
    }
  },

  updateMessage: async ({ commit }, { channelId, messageId, data }) => {
    try {
      const response = await InternalChatMessagesAPI.updateMessage(
        channelId,
        messageId,
        data
      );
      const message = response.data;
      commit('UPDATE_MESSAGE', { channelId, message });
      if (message.parent_id) {
        commit('UPDATE_THREAD_REPLY', {
          parentMessageId: message.parent_id,
          reply: message,
        });
      }
      return message;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  deleteMessage: async (
    { commit, state: _state },
    { channelId, messageId }
  ) => {
    try {
      await InternalChatMessagesAPI.deleteMessage(channelId, messageId);
      commit('DELETE_MESSAGE', { channelId, messageId });
      // Also mark deleted in thread replies if applicable
      Object.keys(_state.threadReplies).forEach(parentId => {
        const replies = _state.threadReplies[parentId] || [];
        if (replies.some(r => r.id === messageId)) {
          commit('DELETE_THREAD_REPLY', {
            parentMessageId: Number(parentId),
            messageId,
          });
        }
      });
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  addReaction: async ({ commit }, { channelId, messageId, emoji }) => {
    try {
      const response = await InternalChatMessagesAPI.addReaction(
        messageId,
        emoji
      );
      commit('ADD_REACTION', {
        channelId,
        messageId,
        reaction: response.data,
      });
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  removeReaction: async ({ commit }, { channelId, messageId, reactionId }) => {
    try {
      await InternalChatMessagesAPI.removeReaction(messageId, reactionId);
      commit('REMOVE_REACTION', { channelId, messageId, reactionId });
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  fetchThread: async ({ commit }, { channelId, messageId }) => {
    try {
      const response = await InternalChatMessagesAPI.getThread(
        channelId,
        messageId
      );
      const replies = response.data.replies || response.data || [];
      commit('SET_THREAD_REPLIES', { parentMessageId: messageId, replies });
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  sendThreadReply: async (
    { commit },
    { channelId, parentMessageId, data, files = [] }
  ) => {
    commit('SET_UI_FLAG', { isSending: true });
    try {
      const response = await InternalChatMessagesAPI.createMessage(
        channelId,
        {
          ...data,
          parent_id: parentMessageId,
        },
        files
      );
      const message = response.data;
      commit('ADD_THREAD_REPLY', {
        parentMessageId,
        reply: message,
      });
      if (message.content_attributes?.also_send_in_channel) {
        commit('ADD_MESSAGE', { channelId, message });
      }
      return message;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    } finally {
      commit('SET_UI_FLAG', { isSending: false });
    }
  },

  pinMessage: async ({ commit }, { channelId, messageId }) => {
    try {
      const response = await InternalChatMessagesAPI.pinMessage(
        channelId,
        messageId
      );
      commit('UPDATE_MESSAGE', { channelId, message: response.data });
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  unpinMessage: async ({ commit }, { channelId, messageId }) => {
    try {
      const response = await InternalChatMessagesAPI.unpinMessage(
        channelId,
        messageId
      );
      commit('UPDATE_MESSAGE', { channelId, message: response.data });
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  addMessageFromCable: ({ commit }, { channelId, message }) => {
    if (message.parent_id) {
      commit('ADD_THREAD_REPLY', {
        parentMessageId: message.parent_id,
        reply: message,
      });
      commit('INCREMENT_REPLY_COUNT', {
        channelId,
        parentMessageId: message.parent_id,
      });
      if (message.content_attributes?.also_send_in_channel) {
        commit('ADD_MESSAGE', { channelId, message });
      }
      return;
    }
    commit('ADD_MESSAGE', { channelId, message });
  },

  updateMessageFromCable: ({ commit }, { channelId, message }) => {
    commit('UPDATE_MESSAGE', { channelId, message });
  },

  deleteMessageFromCable: ({ commit }, { channelId, messageId }) => {
    commit('DELETE_MESSAGE', { channelId, messageId });
  },

  addReactionFromCable: ({ commit }, { channelId, messageId, reaction }) => {
    commit('ADD_REACTION', { channelId, messageId, reaction });
  },

  removeReactionFromCable: (
    { commit },
    { channelId, messageId, reactionId }
  ) => {
    commit('REMOVE_REACTION', { channelId, messageId, reactionId });
  },
};

const mutations = {
  RESET(_state) {
    Object.assign(_state, initialState());
  },
  SET_MESSAGES(_state, { channelId, messages }) {
    _state.records = {
      ..._state.records,
      [channelId]: messages,
    };
  },

  PREPEND_MESSAGES(_state, { channelId, messages }) {
    const existing = _state.records[channelId] || [];
    const existingIds = new Set(existing.map(m => m.id));
    const newMessages = messages.filter(m => !existingIds.has(m.id));
    _state.records = {
      ..._state.records,
      [channelId]: [...newMessages, ...existing],
    };
  },

  APPEND_MESSAGES(_state, { channelId, messages }) {
    const existing = _state.records[channelId] || [];
    const existingIds = new Set(existing.map(m => m.id));
    const newMessages = messages.filter(m => !existingIds.has(m.id));
    _state.records = {
      ..._state.records,
      [channelId]: [...existing, ...newMessages],
    };
  },

  ADD_MESSAGE(_state, { channelId, message }) {
    const existing = _state.records[channelId] || [];
    const alreadyExists = existing.some(m => m.id === message.id);
    if (!alreadyExists) {
      _state.records = {
        ..._state.records,
        [channelId]: [...existing, message],
      };
    }
  },

  UPDATE_MESSAGE(_state, { channelId, message }) {
    const existing = _state.records[channelId] || [];
    const index = existing.findIndex(m => m.id === message.id);
    if (index > -1) {
      const updated = [...existing];
      updated[index] = { ...existing[index], ...message };
      _state.records = {
        ..._state.records,
        [channelId]: updated,
      };
    }
  },

  DELETE_MESSAGE(_state, { channelId, messageId }) {
    const messages = _state.records[channelId];
    if (!messages) return;
    const index = messages.findIndex(m => m.id === messageId);
    if (index !== -1) {
      const updated = [...messages];
      updated[index] = {
        ...updated[index],
        content_attributes: {
          ...updated[index].content_attributes,
          deleted: true,
        },
      };
      _state.records = {
        ..._state.records,
        [channelId]: updated,
      };
    }
  },

  ADD_REACTION(_state, { channelId, messageId, reaction }) {
    const applyAdd = message => {
      const currentReactions = message.reactions || [];
      if (currentReactions.some(r => r.id === reaction.id)) return message;
      return { ...message, reactions: [...currentReactions, reaction] };
    };

    const existing = _state.records[channelId] || [];
    const index = existing.findIndex(m => m.id === messageId);
    if (index > -1) {
      const updated = [...existing];
      updated[index] = applyAdd(existing[index]);
      _state.records = { ..._state.records, [channelId]: updated };
    }

    const nextThreadReplies = { ..._state.threadReplies };
    let threadReplyChanged = false;
    Object.keys(nextThreadReplies).forEach(parentId => {
      const replies = nextThreadReplies[parentId] || [];
      const replyIndex = replies.findIndex(r => r.id === messageId);
      if (replyIndex === -1) return;
      const updatedReplies = [...replies];
      updatedReplies[replyIndex] = applyAdd(replies[replyIndex]);
      nextThreadReplies[parentId] = updatedReplies;
      threadReplyChanged = true;
    });
    if (threadReplyChanged) _state.threadReplies = nextThreadReplies;
  },

  REMOVE_REACTION(_state, { channelId, messageId, reactionId }) {
    const applyRemove = message => ({
      ...message,
      reactions: (message.reactions || []).filter(r => r.id !== reactionId),
    });

    const existing = _state.records[channelId] || [];
    const index = existing.findIndex(m => m.id === messageId);
    if (index > -1) {
      const updated = [...existing];
      updated[index] = applyRemove(existing[index]);
      _state.records = { ..._state.records, [channelId]: updated };
    }

    const nextThreadReplies = { ..._state.threadReplies };
    let threadReplyChanged = false;
    Object.keys(nextThreadReplies).forEach(parentId => {
      const replies = nextThreadReplies[parentId] || [];
      const replyIndex = replies.findIndex(r => r.id === messageId);
      if (replyIndex === -1) return;
      const updatedReplies = [...replies];
      updatedReplies[replyIndex] = applyRemove(replies[replyIndex]);
      nextThreadReplies[parentId] = updatedReplies;
      threadReplyChanged = true;
    });
    if (threadReplyChanged) _state.threadReplies = nextThreadReplies;
  },

  SET_THREAD_REPLIES(_state, { parentMessageId, replies }) {
    _state.threadReplies = {
      ..._state.threadReplies,
      [parentMessageId]: replies,
    };
  },

  ADD_THREAD_REPLY(_state, { parentMessageId, reply }) {
    const existing = _state.threadReplies[parentMessageId] || [];
    if (existing.some(r => r.id === reply.id)) return;
    _state.threadReplies = {
      ..._state.threadReplies,
      [parentMessageId]: [...existing, reply],
    };
  },

  UPDATE_THREAD_REPLY(_state, { parentMessageId, reply }) {
    const existing = _state.threadReplies[parentMessageId] || [];
    const index = existing.findIndex(r => r.id === reply.id);
    if (index > -1) {
      const updated = [...existing];
      updated[index] = { ...updated[index], ...reply };
      _state.threadReplies = {
        ..._state.threadReplies,
        [parentMessageId]: updated,
      };
    }
  },

  DELETE_THREAD_REPLY(_state, { parentMessageId, messageId }) {
    const existing = _state.threadReplies[parentMessageId];
    if (!existing) return;
    const index = existing.findIndex(r => r.id === messageId);
    if (index !== -1) {
      const updated = [...existing];
      updated[index] = {
        ...updated[index],
        content_attributes: {
          ...updated[index].content_attributes,
          deleted: true,
        },
      };
      _state.threadReplies = {
        ..._state.threadReplies,
        [parentMessageId]: updated,
      };
    }
  },

  INCREMENT_REPLY_COUNT(_state, { channelId, parentMessageId }) {
    const messages = _state.records[channelId] || [];
    const index = messages.findIndex(m => m.id === parentMessageId);
    if (index > -1) {
      const updated = [...messages];
      updated[index] = {
        ...updated[index],
        replies_count: (updated[index].replies_count || 0) + 1,
      };
      _state.records = {
        ..._state.records,
        [channelId]: updated,
      };
    }
  },

  SET_UI_FLAG(_state, flags) {
    _state.uiFlags = { ..._state.uiFlags, ...flags };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
