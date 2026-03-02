import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import AiAgentsAPI from '../../api/saas/aiAgents';

export const state = {
  records: [],
  currentAgent: null,
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getAiAgents($state) {
    return $state.records;
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getCurrentAgent($state) {
    return $state.currentAgent;
  },
  getAgentById: $state => id => {
    return $state.records.find(agent => agent.id === Number(id));
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.default.SET_AI_AGENTS_UI_FLAG, { isFetching: true });
    try {
      const response = await AiAgentsAPI.get();
      commit(types.default.SET_AI_AGENTS, response.data);
    } finally {
      commit(types.default.SET_AI_AGENTS_UI_FLAG, { isFetching: false });
    }
  },

  show: async ({ commit }, agentId) => {
    commit(types.default.SET_AI_AGENTS_UI_FLAG, { isFetching: true });
    try {
      const response = await AiAgentsAPI.show(agentId);
      commit(types.default.SET_AI_AGENT_CURRENT, response.data);
      return response.data;
    } finally {
      commit(types.default.SET_AI_AGENTS_UI_FLAG, { isFetching: false });
    }
  },

  create: async ({ commit }, agentData) => {
    commit(types.default.SET_AI_AGENTS_UI_FLAG, { isCreating: true });
    try {
      const response = await AiAgentsAPI.create({ ai_agent: agentData });
      commit(types.default.ADD_AI_AGENT, response.data);
      return response.data;
    } finally {
      commit(types.default.SET_AI_AGENTS_UI_FLAG, { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...agentData }) => {
    commit(types.default.SET_AI_AGENTS_UI_FLAG, { isUpdating: true });
    try {
      const response = await AiAgentsAPI.update(id, { ai_agent: agentData });
      commit(types.default.EDIT_AI_AGENT, response.data);
      commit(types.default.SET_AI_AGENT_CURRENT, response.data);
      return response.data;
    } finally {
      commit(types.default.SET_AI_AGENTS_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async ({ commit }, agentId) => {
    commit(types.default.SET_AI_AGENTS_UI_FLAG, { isDeleting: true });
    try {
      await AiAgentsAPI.delete(agentId);
      commit(types.default.DELETE_AI_AGENT, agentId);
    } finally {
      commit(types.default.SET_AI_AGENTS_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.default.SET_AI_AGENTS_UI_FLAG]($state, uiFlag) {
    $state.uiFlags = { ...$state.uiFlags, ...uiFlag };
  },
  [types.default.SET_AI_AGENTS]: MutationHelpers.set,
  [types.default.ADD_AI_AGENT]: MutationHelpers.create,
  [types.default.EDIT_AI_AGENT]: MutationHelpers.update,
  [types.default.DELETE_AI_AGENT]: MutationHelpers.destroy,
  [types.default.SET_AI_AGENT_CURRENT]($state, agent) {
    $state.currentAgent = agent;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
