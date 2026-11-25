import * as types from '../mutation-types';
import ConversationAPI from '../../api/conversations';

// Each update sends the whole label list, so an update waits for the previous
// one on the same conversation, only the latest one writes its result, and a
// failure rolls back to the last list the server confirmed.
const pendingUpdates = {};

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isUpdating: false,
    isError: false,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getConversationLabels: $state => id => {
    return $state.records[Number(id)] || [];
  },
};

export const actions = {
  get: async ({ commit }, conversationId) => {
    commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
      isFetching: true,
    });
    try {
      const response = await ConversationAPI.getLabels(conversationId);
      commit(types.default.SET_CONVERSATION_LABELS, {
        id: conversationId,
        data: response.data.payload,
      });
      commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
        isFetching: false,
      });
    } catch (error) {
      commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
        isFetching: false,
      });
    }
  },
  update: async ({ commit, state: $state }, { conversationId, labels }) => {
    pendingUpdates[conversationId] ??= {
      savedLabels: $state.records[Number(conversationId)],
    };
    const pending = pendingUpdates[conversationId];
    const request = Promise.resolve(pending.request)
      .catch(() => {})
      .then(() => ConversationAPI.updateLabels(conversationId, labels));
    pending.request = request;

    commit(types.default.SET_CONVERSATION_LABELS, {
      id: conversationId,
      data: labels,
    });
    commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
      isUpdating: true,
    });
    try {
      const response = await request;
      pending.savedLabels = response.data.payload;
      if (pending.request !== request) return;
      delete pendingUpdates[conversationId];
      commit(types.default.SET_CONVERSATION_LABELS, {
        id: conversationId,
        data: response.data.payload,
      });
      commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
        isUpdating: false,
        isError: false,
      });
    } catch (error) {
      if (pending.request !== request) return;
      delete pendingUpdates[conversationId];
      commit(types.default.SET_CONVERSATION_LABELS, {
        id: conversationId,
        data: pending.savedLabels,
      });
      commit(types.default.SET_CONVERSATION_LABELS_UI_FLAG, {
        isUpdating: false,
        isError: true,
      });
    }
  },
  setBulkConversationLabels({ commit }, conversations) {
    commit(types.default.SET_BULK_CONVERSATION_LABELS, conversations);
  },
  setConversationLabel({ commit }, { id, data }) {
    commit(types.default.SET_CONVERSATION_LABELS, { id, data });
  },
};

export const mutations = {
  [types.default.SET_CONVERSATION_LABELS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_CONVERSATION_LABELS]: ($state, { id, data }) => {
    $state.records = { ...$state.records, [id]: data };
  },
  [types.default.SET_BULK_CONVERSATION_LABELS]: ($state, conversations) => {
    const updatedRecords = { ...$state.records };
    conversations.forEach(conversation => {
      updatedRecords[conversation.id] = conversation.labels;
    });

    $state.records = updatedRecords;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
