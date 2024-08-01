import Vue from 'vue';
import * as types from '../mutation-types';
import TicketsAPI from '../../api/tickets';

const state = {
  record: [],
  uiFlags: {
    isCreating: false,
    isFetching: false,
    isUpdating: false,
  },
  uiFlagsPage: {
    isFetching: false,
  },
  stats: {
    open: 0,
    closed: 0,
    all: 0,
  },
};

export const getters = {
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getUIFlagsPage($state) {
    return $state.uiFlagsPage;
  },
  getTickets($state) {
    return $state.record;
  },
  getStats($state) {
    return $state.stats;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.default.SET_TICKETS_UI_FLAG, { isFetching: true });
    try {
      const response = await TicketsAPI.get();
      commit(types.default.SET_TICKETS, response.data.payload);
      commit(types.default.SET_TICKETS_UI_FLAG, {
        isFetching: false,
      });
    } catch (error) {
      commit(types.default.SET_TICKETS_UI_FLAG, {
        isFetching: false,
      });
    }
  },
  getConversationTickets: async ({ commit }, conversationId) => {
    commit(types.default.SET_TICKETS_UI_FLAG, { isFetching: true });
    try {
      const response = await TicketsAPI.getConversationTickets(conversationId);
      commit(types.default.SET_TICKETS, response.data.payload);
      commit(types.default.SET_TICKETS_UI_FLAG, {
        isFetching: false,
      });
    } catch (error) {
      commit(types.default.SET_TICKETS_UI_FLAG, {
        isFetching: false,
      });
    }
  },
  getAllTickets: async ({ commit }) => {
    commit(types.default.SET_TICKETS_UI_FLAG_PAGE, { isFetching: true });
    try {
      const response = await TicketsAPI.getAll();
      commit(types.default.SET_TICKETS, response.data.payload);
      commit(types.default.SET_TICKETS_UI_FLAG_PAGE, {
        isFetching: false,
      });
    } catch (error) {
      commit(types.default.SET_TICKETS_UI_FLAG_PAGE, {
        isFetching: false,
      });
    }
  },
  create: async (
    { commit },
    { title, description, status, assigneeId, conversationId }
  ) => {
    commit(types.default.SET_TICKETS_UI_FLAG, { isCreating: true });
    try {
      const response = await TicketsAPI.create({
        title,
        description,
        status,
        assignee_id: assigneeId,
        conversation_id: conversationId,
      });
      commit(types.default.SET_TICKETS, response.data);
      commit(types.default.SET_TICKETS_UI_FLAG, {
        isCreating: false,
      });
    } catch (error) {
      commit(types.default.SET_TICKETS_UI_FLAG, {
        isCreating: false,
      });
      throw error;
    }
  },
  update: async ({ commit }, { selectedEmailFlags, selectedPushFlags }) => {
    commit(types.default.SET_TICKETS_UI_FLAG, { isUpdating: true });
    try {
      const response = await TicketsAPI.update({
        notification_settings: {
          selected_email_flags: selectedEmailFlags,
          selected_push_flags: selectedPushFlags,
        },
      });
      commit(types.default.SET_TICKETS, response.data);
      commit(types.default.SET_TICKETS_UI_FLAG, {
        isUpdating: false,
      });
    } catch (error) {
      commit(types.default.SET_TICKETS_UI_FLAG, {
        isUpdating: false,
      });
      throw error;
    }
  },
};

export const mutations = {
  [types.default.SET_TICKETS_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.SET_TICKETS]: ($state, data) => {
    Vue.set($state, 'record', data);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
