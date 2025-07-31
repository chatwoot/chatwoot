export const mutations = {
  setUIFlag(state, data) {
    state.uiFlags = {
      ...state.uiFlags,
      ...data,
    };
  },

  setAssignmentPolicies(state, policies) {
    state.records = {};
    policies.forEach(policy => {
      state.records[policy.id] = policy;
    });
  },

  setAssignmentPolicy(state, policy) {
    state.records = {
      ...state.records,
      [policy.id]: policy,
    };
  },

  deleteAssignmentPolicy(state, id) {
    const { [id]: deleted, ...rest } = state.records;
    state.records = rest;
  },
};
