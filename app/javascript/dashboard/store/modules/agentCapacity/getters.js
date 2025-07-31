export const getters = {
  getCapacityPolicies: state => Object.values(state.policies),
  getCapacityPolicy: state => id => state.policies[id],
  getAgentCapacities: state => Object.values(state.agentCapacities),
  getAgentCapacity: state => agentId => state.agentCapacities[agentId],
  getUIFlags: state => state.uiFlags,

  getActivePolicies: state => {
    return Object.values(state.policies).filter(policy => policy.active);
  },

  getAgentsByPolicy: state => policyId => {
    return Object.values(state.agentCapacities).filter(
      capacity => capacity.agent_capacity_policy_id === policyId
    );
  },

  getAvailableCapacity: state => agentId => {
    const capacity = state.agentCapacities[agentId];
    if (!capacity) return 0;

    return capacity.max_capacity - capacity.current_load;
  },

  getAgentsAtCapacity: state => {
    return Object.values(state.agentCapacities).filter(
      capacity => capacity.current_load >= capacity.max_capacity
    );
  },
};
