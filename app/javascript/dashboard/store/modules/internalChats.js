import InternalChatsAPI from '../../api/internalChats';

const PAGE_SIZE = 50;

const SET_UI_FLAG = 'SET_INTERNAL_CHATS_UI_FLAG';
const SET_ROOMS = 'SET_INTERNAL_CHATS_ROOMS';
const SET_MESSAGES = 'SET_INTERNAL_CHATS_MESSAGES';
const PREPEND_MESSAGES = 'PREPEND_INTERNAL_CHATS_MESSAGES';
const ADD_MESSAGE = 'ADD_INTERNAL_CHATS_MESSAGE';
const REMOVE_MESSAGE = 'REMOVE_INTERNAL_CHATS_MESSAGE';
const REPLACE_MESSAGE = 'REPLACE_INTERNAL_CHATS_MESSAGE';
const MARK_MESSAGE_FAILED = 'MARK_INTERNAL_CHATS_MESSAGE_FAILED';
const UPDATE_ROOM_PREVIEW = 'UPDATE_INTERNAL_CHATS_ROOM_PREVIEW';
const SET_HAS_MORE = 'SET_INTERNAL_CHATS_HAS_MORE';

export const state = {
  records: [],
  messagesByRoom: {},
  hasMoreByRoom: {},
  uiFlags: {
    isFetching: false,
    isFetchingMessages: false,
    isCreating: false,
  },
};

export const getters = {
  getRooms: $state => $state.records,
  getMessagesByRoomId: $state => roomId => $state.messagesByRoom[roomId] || [],
  getHasMoreByRoomId: $state => roomId => Boolean($state.hasMoreByRoom[roomId]),
  getUIFlags: $state => $state.uiFlags,
};

export const actions = {
  async fetchRooms({ commit }) {
    commit(SET_UI_FLAG, { isFetching: true });
    try {
      const { data } = await InternalChatsAPI.getRooms();
      commit(SET_ROOMS, data);
      return data;
    } finally {
      commit(SET_UI_FLAG, { isFetching: false });
    }
  },

  async fetchMessages({ commit }, { conversationId, beforeId } = {}) {
    commit(SET_UI_FLAG, { isFetchingMessages: true });
    try {
      const params = {};
      if (beforeId) params.before_id = beforeId;
      const { data } = await InternalChatsAPI.getMessages(
        conversationId,
        params
      );
      const batch = data.payload || [];
      const messages = [...batch].reverse();
      commit(SET_HAS_MORE, {
        conversationId,
        hasMore: batch.length >= PAGE_SIZE,
      });
      if (beforeId) {
        commit(PREPEND_MESSAGES, { conversationId, messages });
      } else {
        commit(SET_MESSAGES, { conversationId, messages });
      }
      return messages;
    } finally {
      commit(SET_UI_FLAG, { isFetchingMessages: false });
    }
  },

  async sendMessage(
    { commit },
    { conversationId, content, currentUserId, currentUser }
  ) {
    const tempId = `tmp-${Date.now()}-${Math.random()
      .toString(36)
      .slice(2, 8)}`;
    const createdAt = Math.floor(Date.now() / 1000);
    const optimistic = {
      id: tempId,
      internal_conversation_id: conversationId,
      user_id: currentUserId || null,
      content,
      created_at: createdAt,
      pending: true,
      error: false,
      user: currentUser || null,
    };

    commit(ADD_MESSAGE, { conversationId, message: optimistic });
    commit(UPDATE_ROOM_PREVIEW, {
      conversationId,
      preview: content,
      lastActivityAt: createdAt,
    });
    commit(SET_UI_FLAG, { isCreating: true });

    try {
      const { data } = await InternalChatsAPI.createMessage(
        conversationId,
        content
      );
      commit(REPLACE_MESSAGE, {
        conversationId,
        tempId,
        message: { ...data, pending: false, error: false },
      });
      return data;
    } catch (error) {
      commit(MARK_MESSAGE_FAILED, { conversationId, tempId });
      throw error;
    } finally {
      commit(SET_UI_FLAG, { isCreating: false });
    }
  },

  async retryMessage(
    { dispatch },
    { conversationId, message, currentUserId, currentUser }
  ) {
    if (!message?.content) return null;
    await dispatch('removeMessage', {
      conversationId,
      messageId: message.id,
    });
    return dispatch('sendMessage', {
      conversationId,
      content: message.content,
      currentUserId,
      currentUser,
    });
  },

  removeMessage({ commit }, { conversationId, messageId }) {
    commit(REMOVE_MESSAGE, { conversationId, messageId });
  },

  handleMessageCreated({ commit, state }, payload) {
    const message = payload?.internal_message || payload;
    if (!message?.internal_conversation_id) return;

    const list = state.messagesByRoom[message.internal_conversation_id] || [];
    const tempMatch = list.find(
      m => m.id?.toString().startsWith('tmp-') && m.content === message.content
    );

    if (tempMatch) {
      commit(REPLACE_MESSAGE, {
        conversationId: message.internal_conversation_id,
        tempId: tempMatch.id,
        message: { ...message, pending: false, error: false },
      });
    } else {
      commit(ADD_MESSAGE, {
        conversationId: message.internal_conversation_id,
        message,
      });
    }
    commit(UPDATE_ROOM_PREVIEW, {
      conversationId: message.internal_conversation_id,
      preview: message.content,
      lastActivityAt: message.created_at,
    });
  },
};

export const mutations = {
  [SET_UI_FLAG]($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  [SET_ROOMS]($state, data) {
    $state.records = Array.isArray(data) ? data : [];
  },
  [SET_MESSAGES]($state, { conversationId, messages }) {
    $state.messagesByRoom = {
      ...$state.messagesByRoom,
      [conversationId]: messages,
    };
  },
  [PREPEND_MESSAGES]($state, { conversationId, messages }) {
    const existing = $state.messagesByRoom[conversationId] || [];
    const existingIds = new Set(existing.map(m => m.id));
    const unique = messages.filter(m => !existingIds.has(m.id));
    $state.messagesByRoom = {
      ...$state.messagesByRoom,
      [conversationId]: [...unique, ...existing],
    };
  },
  [ADD_MESSAGE]($state, { conversationId, message }) {
    const existing = $state.messagesByRoom[conversationId] || [];
    if (existing.some(m => m.id === message.id)) return;
    $state.messagesByRoom = {
      ...$state.messagesByRoom,
      [conversationId]: [...existing, message],
    };
  },
  [REMOVE_MESSAGE]($state, { conversationId, messageId }) {
    const existing = $state.messagesByRoom[conversationId] || [];
    $state.messagesByRoom = {
      ...$state.messagesByRoom,
      [conversationId]: existing.filter(m => m.id !== messageId),
    };
  },
  [REPLACE_MESSAGE]($state, { conversationId, tempId, message }) {
    const list = $state.messagesByRoom[conversationId] || [];
    $state.messagesByRoom = {
      ...$state.messagesByRoom,
      [conversationId]: list.map(m =>
        m.id === tempId ? { ...message, pending: false, error: false } : m
      ),
    };
  },
  [MARK_MESSAGE_FAILED]($state, { conversationId, tempId }) {
    const list = $state.messagesByRoom[conversationId] || [];
    $state.messagesByRoom = {
      ...$state.messagesByRoom,
      [conversationId]: list.map(m =>
        m.id === tempId ? { ...m, pending: false, error: true } : m
      ),
    };
  },
  [UPDATE_ROOM_PREVIEW]($state, { conversationId, preview, lastActivityAt }) {
    $state.records = $state.records
      .map(room =>
        room.id === conversationId
          ? {
              ...room,
              last_message_preview: preview,
              last_activity_at: lastActivityAt,
            }
          : room
      )
      .sort((a, b) => (b.last_activity_at || 0) - (a.last_activity_at || 0));
  },
  [SET_HAS_MORE]($state, { conversationId, hasMore }) {
    $state.hasMoreByRoom = {
      ...$state.hasMoreByRoom,
      [conversationId]: hasMore,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
