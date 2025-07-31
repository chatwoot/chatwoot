import agentCapacityPoliciesAPI from '../../../api/agentCapacityPolicies';

export const actions = {
  get: async ({ commit }, params = {}) => {
    commit('setUIFlag', { isFetching: true });
    try {
      const response = await agentCapacityPoliciesAPI.get(params);
      const policies = response.data.agent_capacity_policies || response.data;
      commit('setCapacityPolicies', policies);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  show: async ({ commit }, id) => {
    try {
      const response = await agentCapacityPoliciesAPI.show(id);
      const policy = response.data.agent_capacity_policy || response.data;
      commit('setCapacityPolicy', policy);
      return policy;
    } catch (error) {
      throw new Error(error);
    }
  },

  create: async ({ commit }, data) => {
    commit('setUIFlag', { isCreating: true });
    try {
      const response = await agentCapacityPoliciesAPI.create(data);
      const policy = response.data.agent_capacity_policy || response.data;
      commit('setCapacityPolicy', policy);
      return policy;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isCreating: false });
    }
  },

  update: async ({ commit }, { id, ...data }) => {
    commit('setUIFlag', { isUpdating: true });
    try {
      const response = await agentCapacityPoliciesAPI.update(id, data);
      commit('setCapacityPolicy', response.data);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isUpdating: false });
    }
  },

  delete: async ({ commit }, id) => {
    commit('setUIFlag', { isDeleting: true });
    try {
      await agentCapacityPoliciesAPI.delete(id);
      commit('deleteCapacityPolicy', id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isDeleting: false });
    }
  },

  assignUser: async ({ commit }, { id, userId }) => {
    commit('setUIFlag', { isAssigningAgents: true });
    try {
      const response = await agentCapacityPoliciesAPI.assignUser(id, userId);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isAssigningAgents: false });
    }
  },

  removeUser: async ({ commit }, { id, userId }) => {
    commit('setUIFlag', { isAssigningAgents: true });
    try {
      const response = await agentCapacityPoliciesAPI.removeUser(id, userId);
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isAssigningAgents: false });
    }
  },

  setInboxLimit: async ({ commit }, { id, inboxId, conversationLimit }) => {
    commit('setUIFlag', { isUpdating: true });
    try {
      const response = await agentCapacityPoliciesAPI.setInboxLimit(
        id,
        inboxId,
        conversationLimit
      );
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isUpdating: false });
    }
  },

  removeInboxLimit: async ({ commit }, { id, inboxId }) => {
    commit('setUIFlag', { isUpdating: true });
    try {
      const response = await agentCapacityPoliciesAPI.removeInboxLimit(
        id,
        inboxId
      );
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isUpdating: false });
    }
  },

  getAgentCapacity: async ({ commit, rootGetters }, { agentId, inboxId }) => {
    commit('setUIFlag', { isFetching: true });
    try {
      const accountId = rootGetters['auth/getCurrentAccountId'];
      const response = await agentCapacityPoliciesAPI.getAgentCapacity(
        accountId,
        agentId,
        inboxId
      );
      commit('setAgentCapacity', { agentId, data: response.data });
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },
};
