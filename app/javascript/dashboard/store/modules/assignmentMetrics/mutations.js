export const mutations = {
  setUIFlag(state, data) {
    state.uiFlags = {
      ...state.uiFlags,
      ...data,
    };
  },

  setFilters(state, filters) {
    state.filters = {
      ...state.filters,
      ...filters,
    };
  },

  setOverviewMetrics(state, metrics) {
    state.metrics.overview = metrics;
  },

  setAgentHistory(state, history) {
    state.metrics.agentHistory = history;
  },

  setPolicyPerformance(state, performance) {
    state.metrics.policyPerformance = performance;
  },

  setAgentUtilization(state, utilization) {
    state.metrics.agentUtilization = utilization;
  },

  setAssignmentDistribution(state, distribution) {
    state.metrics.assignmentDistribution = distribution;
  },

  setAssignmentTrends(state, trends) {
    state.metrics.assignmentTrends = trends;
  },
};
