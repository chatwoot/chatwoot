import ScheduledMessagesApi from '../../api/scheduledMessages';
import types from '../mutation-types';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getScheduledMessages: state => conversationId => {
    const allMessages = Object.values(state.records);
    const convId = Number(conversationId);
    const filtered = allMessages.filter(msg =>
      msg.conversation_id === convId || msg.conversation_display_id === convId
    );
    return filtered.sort((a, b) => a.scheduled_at - b.scheduled_at);
  },
  getAllScheduledMessages: state => {
    return Object.values(state.records).sort(
      (a, b) => a.scheduled_at - b.scheduled_at
    );
  },
  getScheduledMessage: state => id => {
    return state.records[id];
  },
  getUIFlags: state => state.uiFlags,
};

export const actions = {
  get: async ({ commit }, conversationId) => {
    commit(types.SET_SCHEDULED_MESSAGES_UI_FLAG, { isFetching: true });
    try {
      const response = await ScheduledMessagesApi.getByConversation(
        conversationId
      );
      const messages = response.data.payload || response.data;
      commit(types.SET_SCHEDULED_MESSAGES, messages);
    } catch (error) {
      throw error;
    } finally {
      commit(types.SET_SCHEDULED_MESSAGES_UI_FLAG, { isFetching: false });
    }
  },

  getAll: async ({ commit }) => {
    commit(types.SET_SCHEDULED_MESSAGES_UI_FLAG, { isFetching: true });
    try {
      const { data } = await ScheduledMessagesApi.getAll();
      commit(types.SET_SCHEDULED_MESSAGES, data.payload || data);
    } catch (error) {
      throw error;
    } finally {
      commit(types.SET_SCHEDULED_MESSAGES_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, scheduledMessageData) => {
    commit(types.SET_SCHEDULED_MESSAGES_UI_FLAG, { isCreating: true });
    try {
      const { data } = await ScheduledMessagesApi.create(scheduledMessageData);
      commit(types.ADD_SCHEDULED_MESSAGE, data);
      return data;
    } catch (error) {
      throw error;
    } finally {
      commit(types.SET_SCHEDULED_MESSAGES_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...scheduledMessageData }) => {
    commit(types.SET_SCHEDULED_MESSAGES_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await ScheduledMessagesApi.update(
        id,
        scheduledMessageData
      );
      commit(types.UPDATE_SCHEDULED_MESSAGE, data);
      return data;
    } catch (error) {
      throw error;
    } finally {
      commit(types.SET_SCHEDULED_MESSAGES_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit(types.SET_SCHEDULED_MESSAGES_UI_FLAG, { isDeleting: true });
    try {
      await ScheduledMessagesApi.delete(id);
      commit(types.DELETE_SCHEDULED_MESSAGE, id);
    } catch (error) {
      throw error;
    } finally {
      commit(types.SET_SCHEDULED_MESSAGES_UI_FLAG, { isDeleting: false });
    }
  },

  sendNow: async (_, id) => {
    try {
      await ScheduledMessagesApi.sendNow(id);
    } catch (error) {
      throw error;
    }
  },
};

export const mutations = {
  [types.SET_SCHEDULED_MESSAGES]: (state, data) => {
    const messages = Array.isArray(data) ? data : [data];
    messages.forEach(msg => {
      state.records[msg.id] = msg;
    });
  },

  [types.ADD_SCHEDULED_MESSAGE]: (state, data) => {
    state.records[data.id] = data;
  },

  [types.UPDATE_SCHEDULED_MESSAGE]: (state, data) => {
    state.records[data.id] = data;
  },

  [types.DELETE_SCHEDULED_MESSAGE]: (state, id) => {
    delete state.records[id];
  },

  [types.SET_SCHEDULED_MESSAGES_UI_FLAG]: (state, flag) => {
    state.uiFlags = { ...state.uiFlags, ...flag };
  },

  [types.CLEAR_SCHEDULED_MESSAGES]: state => {
    state.records = {};
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
