import types from '../mutation-types';
import RecurringScheduledMessagesAPI from '../../api/recurringScheduledMessages';

export const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getAllByConversation: _state => conversationId => {
    return _state.records[Number(conversationId)] || [];
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  async get({ commit }, { conversationId }) {
    commit(types.SET_RECURRING_SCHEDULED_MESSAGES_UI_FLAG, {
      isFetching: true,
    });
    try {
      const normalizedConversationId = Number(conversationId);
      const { data } = await RecurringScheduledMessagesAPI.get(
        normalizedConversationId
      );
      commit(types.SET_RECURRING_SCHEDULED_MESSAGES, {
        conversationId: normalizedConversationId,
        data: data.payload,
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_RECURRING_SCHEDULED_MESSAGES_UI_FLAG, {
        isFetching: false,
      });
    }
  },

  async create({ commit }, { conversationId, payload }) {
    commit(types.SET_RECURRING_SCHEDULED_MESSAGES_UI_FLAG, {
      isCreating: true,
    });
    try {
      const normalizedConversationId = Number(conversationId);
      const { data } = await RecurringScheduledMessagesAPI.create(
        normalizedConversationId,
        payload
      );
      commit(types.ADD_RECURRING_SCHEDULED_MESSAGE, {
        conversationId: normalizedConversationId,
        data,
      });
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_RECURRING_SCHEDULED_MESSAGES_UI_FLAG, {
        isCreating: false,
      });
    }
  },

  async update(
    { commit },
    { conversationId, recurringScheduledMessageId, payload }
  ) {
    commit(types.SET_RECURRING_SCHEDULED_MESSAGES_UI_FLAG, {
      isUpdating: true,
    });
    try {
      const normalizedConversationId = Number(conversationId);
      const { data } = await RecurringScheduledMessagesAPI.update(
        normalizedConversationId,
        recurringScheduledMessageId,
        payload
      );
      commit(types.UPDATE_RECURRING_SCHEDULED_MESSAGE, {
        conversationId: normalizedConversationId,
        data,
      });
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_RECURRING_SCHEDULED_MESSAGES_UI_FLAG, {
        isUpdating: false,
      });
    }
  },

  async delete({ commit }, { conversationId, recurringScheduledMessageId }) {
    commit(types.SET_RECURRING_SCHEDULED_MESSAGES_UI_FLAG, {
      isDeleting: true,
    });
    try {
      const normalizedConversationId = Number(conversationId);
      const response = await RecurringScheduledMessagesAPI.delete(
        normalizedConversationId,
        recurringScheduledMessageId
      );
      commit(types.UPDATE_RECURRING_SCHEDULED_MESSAGE, {
        conversationId: normalizedConversationId,
        data: response.data,
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_RECURRING_SCHEDULED_MESSAGES_UI_FLAG, {
        isDeleting: false,
      });
    }
  },

  upsertFromEvent({ commit, state: localState }, recurringScheduledMessage) {
    const conversationId = Number(recurringScheduledMessage.conversation_id);
    const records = localState.records[conversationId] || [];
    const exists = records.some(
      record => record.id === recurringScheduledMessage.id
    );

    commit(
      exists
        ? types.UPDATE_RECURRING_SCHEDULED_MESSAGE
        : types.ADD_RECURRING_SCHEDULED_MESSAGE,
      { conversationId, data: recurringScheduledMessage }
    );
  },

  removeFromEvent({ commit }, recurringScheduledMessage) {
    commit(types.DELETE_RECURRING_SCHEDULED_MESSAGE, {
      conversationId: Number(recurringScheduledMessage.conversation_id),
      recurringScheduledMessageId: recurringScheduledMessage.id,
    });
  },
};

export const mutations = {
  [types.SET_RECURRING_SCHEDULED_MESSAGES_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },

  [types.SET_RECURRING_SCHEDULED_MESSAGES]($state, { conversationId, data }) {
    $state.records = {
      ...$state.records,
      [Number(conversationId)]: data,
    };
  },

  [types.ADD_RECURRING_SCHEDULED_MESSAGE]($state, { conversationId, data }) {
    const normalizedConversationId = Number(conversationId);
    const records = $state.records[normalizedConversationId] || [];
    const existingIndex = records.findIndex(record => record.id === data.id);

    if (existingIndex > -1) {
      records[existingIndex] = data;
    } else {
      records.push(data);
    }

    $state.records = {
      ...$state.records,
      [normalizedConversationId]: [...records],
    };
  },

  [types.UPDATE_RECURRING_SCHEDULED_MESSAGE]($state, { conversationId, data }) {
    const normalizedConversationId = Number(conversationId);
    const records = $state.records[normalizedConversationId] || [];
    const existingIndex = records.findIndex(record => record.id === data.id);

    if (existingIndex > -1) {
      records[existingIndex] = data;
    } else {
      records.push(data);
    }

    $state.records = {
      ...$state.records,
      [normalizedConversationId]: [...records],
    };
  },

  [types.DELETE_RECURRING_SCHEDULED_MESSAGE](
    $state,
    { conversationId, recurringScheduledMessageId }
  ) {
    const normalizedConversationId = Number(conversationId);
    const records = $state.records[normalizedConversationId] || [];
    $state.records = {
      ...$state.records,
      [normalizedConversationId]: records.filter(
        record => record.id !== recurringScheduledMessageId
      ),
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
