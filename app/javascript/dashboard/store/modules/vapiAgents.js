import VapiAgentsAPI from '../../api/vapiAgents';
import { throwErrorMessage } from '../utils/api';

const types = {
  SET_VAPI_AGENTS_UI_FLAG: 'SET_VAPI_AGENTS_UI_FLAG',
  SET_VAPI_AGENTS: 'SET_VAPI_AGENTS',
  SET_VAPI_AGENT: 'SET_VAPI_AGENT',
  ADD_VAPI_AGENT: 'ADD_VAPI_AGENT',
  UPDATE_VAPI_AGENT: 'UPDATE_VAPI_AGENT',
  DELETE_VAPI_AGENT: 'DELETE_VAPI_AGENT',
};

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

const getters = {
  getVapiAgents: $state => Object.values($state.records),
  getVapiAgentById: $state => id => $state.records[id],
  getUIFlags: $state => $state.uiFlags,
};

const actions = {
  get: async ({ commit }) => {
    commit(types.SET_VAPI_AGENTS_UI_FLAG, { isFetching: true });
    try {
      const response = await VapiAgentsAPI.get();
      commit(types.SET_VAPI_AGENTS, response.data.data);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_VAPI_AGENTS_UI_FLAG, { isFetching: false });
    }
  },

  show: async ({ commit }, id) => {
    commit(types.SET_VAPI_AGENTS_UI_FLAG, { isFetching: true });
    try {
      const response = await VapiAgentsAPI.show(id);
      commit(types.SET_VAPI_AGENT, response.data.data);
      return response.data.data;
    } catch (error) {
      throwErrorMessage(error);
      return undefined;
    } finally {
      commit(types.SET_VAPI_AGENTS_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, data) => {
    commit(types.SET_VAPI_AGENTS_UI_FLAG, { isCreating: true });
    try {
      const response = await VapiAgentsAPI.create(data);
      commit(types.ADD_VAPI_AGENT, response.data.data);
      return response.data.data;
    } catch (error) {
      throwErrorMessage(error);
      return undefined;
    } finally {
      commit(types.SET_VAPI_AGENTS_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...data }) => {
    commit(types.SET_VAPI_AGENTS_UI_FLAG, { isUpdating: true });
    try {
      const response = await VapiAgentsAPI.update(id, data);
      commit(types.UPDATE_VAPI_AGENT, response.data.data);
      return response.data.data;
    } catch (error) {
      throwErrorMessage(error);
      return undefined;
    } finally {
      commit(types.SET_VAPI_AGENTS_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit(types.SET_VAPI_AGENTS_UI_FLAG, { isDeleting: true });
    try {
      await VapiAgentsAPI.delete(id);
      commit(types.DELETE_VAPI_AGENT, id);
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.SET_VAPI_AGENTS_UI_FLAG, { isDeleting: false });
    }
  },

  fetchFromVapi: async (context, { vapiAgentId, inboxId }) => {
    try {
      const response = await VapiAgentsAPI.fetchFromVapi(vapiAgentId, inboxId);
      // Return the data without adding to store
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },

  importFromVapi: async ({ commit }, { vapiAgentId, inboxId }) => {
    try {
      const response = await VapiAgentsAPI.importFromVapi(vapiAgentId, inboxId);
      // Add the imported agent to the store
      if (response.data && response.data.data) {
        commit(types.ADD_VAPI_AGENT, response.data.data);
      }
      return response.data;
    } catch (error) {
      throwErrorMessage(error);
      throw error;
    }
  },
};

const mutations = {
  [types.SET_VAPI_AGENTS_UI_FLAG]($state, uiFlag) {
    $state.uiFlags = { ...$state.uiFlags, ...uiFlag };
  },

  [types.SET_VAPI_AGENTS]($state, data) {
    const records = {};
    data.forEach(agent => {
      records[agent.id] = agent;
    });
    $state.records = records;
  },

  [types.SET_VAPI_AGENT]($state, data) {
    $state.records = { ...$state.records, [data.id]: data };
  },

  [types.ADD_VAPI_AGENT]($state, data) {
    $state.records = { ...$state.records, [data.id]: data };
  },

  [types.UPDATE_VAPI_AGENT]($state, data) {
    $state.records = { ...$state.records, [data.id]: data };
  },

  [types.DELETE_VAPI_AGENT]($state, id) {
    const { [id]: deleted, ...records } = $state.records;
    $state.records = records;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
