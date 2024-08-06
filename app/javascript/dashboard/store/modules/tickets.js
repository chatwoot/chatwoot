import Vue from 'vue';
import * as types from '../mutation-types';
import TicketsAPI from '../../api/tickets';

const state = {
  records: [],
  selectedTicket: null,
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
    return $state.records;
  },
  getStats($state) {
    return $state.stats;
  },
  getTicket: $state => {
    return $state.selectedTicket;
  },
};

export const actions = {
  get: async ({ commit }, ticketId) => {
    try {
      const response = await TicketsAPI.show(ticketId);

      commit(types.default.SET_TICKET, response.data);
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
      const response = await TicketsAPI.get();
      commit(types.default.SET_TICKETS, response.data.payload);
      commit(types.default.SET_TICKETS_STATS, response.data.meta);
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
  update: async ({ commit }, { ticketId, body }) => {
    commit(types.default.SET_TICKETS_UI_FLAG, { isUpdating: true });
    try {
      const response = await TicketsAPI.update(ticketId, {
        body,
      });
      commit(types.default.UPDATE_TICKET, response.data);
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
  assign: async ({ commit }, { ticketId, assigneeId }) => {
    commit(types.default.SET_TICKETS_UI_FLAG, { isUpdating: true });
    try {
      const response = await TicketsAPI.assign(ticketId, assigneeId);
      commit(types.default.UPDATE_TICKET, response.data);
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
  [types.default.SET_TICKETS_UI_FLAG_PAGE]($state, data) {
    $state.uiFlagsPage = {
      ...$state.uiFlagsPage,
      ...data,
    };
  },
  [types.default.SET_TICKETS]: ($state, data) => {
    Vue.set($state, 'records', data);
  },
  [types.default.SET_TICKET]: ($state, data) => {
    Vue.set($state, 'selectedTicket', data);
  },
  [types.default.UPDATE_TICKET]: ($state, data) => {
    const index = $state.records.findIndex(ticket => ticket.id === data.id);
    if (index !== -1) {
      Vue.set($state.records, index, data);
    }
  },
  [types.default.SET_TICKETS_STATS]($state, data) {
    $state.stats = data;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
