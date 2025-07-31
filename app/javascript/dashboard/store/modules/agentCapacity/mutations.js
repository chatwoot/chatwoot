export const mutations = {
  setUIFlag(state, data) {
    state.uiFlags = {
      ...state.uiFlags,
      ...data,
    };
  },

  setCapacityPolicies(state, response) {
    // Handle both array and object with agent_capacity_policies key
    const policies = response.agent_capacity_policies || response;
    state.policies = {};
    if (Array.isArray(policies)) {
      policies.forEach(policy => {
        state.policies[policy.id] = policy;
      });
    }
  },

  setCapacityPolicy(state, response) {
    // Handle both direct policy and object with agent_capacity_policy key
    const policy = response.agent_capacity_policy || response;
    state.policies = {
      ...state.policies,
      [policy.id]: policy,
    };
  },

  deleteCapacityPolicy(state, id) {
    const { [id]: deleted, ...rest } = state.policies;
    state.policies = rest;
  },

  setAgentCapacities(state, capacities) {
    if (Array.isArray(capacities)) {
      const newCapacities = {};
      capacities.forEach(capacity => {
        newCapacities[capacity.agent_id] = capacity;
      });
      state.agentCapacities = {
        ...state.agentCapacities,
        ...newCapacities,
      };
    } else {
      state.agentCapacities = capacities;
    }
  },

  setAgentCapacity(state, { agentId, data }) {
    state.agentCapacities = {
      ...state.agentCapacities,
      [agentId]: data,
    };
  },

  deleteAgentCapacity(state, agentId) {
    const { [agentId]: deleted, ...rest } = state.agentCapacities;
    state.agentCapacities = rest;
  },
};
