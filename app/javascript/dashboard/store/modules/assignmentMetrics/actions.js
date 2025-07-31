import assignmentMetricsAPI from '../../../api/assignmentMetrics';

export const actions = {
  getMetrics: async ({ commit, state }) => {
    commit('setUIFlag', { isFetching: true });
    try {
      const response = await assignmentMetricsAPI.get(state.filters);
      commit('setOverviewMetrics', response.data.overview || {});
      commit('setAssignmentTrends', response.data.trends || []);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetching: false });
    }
  },

  getAgentHistory: async ({ commit, state }) => {
    commit('setUIFlag', { isFetchingHistory: true });
    try {
      const response = await assignmentMetricsAPI.getAllAgentsHistory(
        state.filters
      );
      commit('setAgentHistory', response.data.agent_history || []);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetchingHistory: false });
    }
  },

  getAgentHistoryById: async ({ commit, state }, userId) => {
    commit('setUIFlag', { isFetchingHistory: true });
    try {
      const response = await assignmentMetricsAPI.getAgentHistory(
        userId,
        state.filters
      );
      return response.data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetchingHistory: false });
    }
  },

  getPolicyPerformance: async ({ commit, state }) => {
    commit('setUIFlag', { isFetchingPerformance: true });
    try {
      const response = await assignmentMetricsAPI.getPolicyPerformance(
        state.filters
      );
      commit('setPolicyPerformance', response.data.policy_performance || []);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetchingPerformance: false });
    }
  },

  getAgentUtilization: async ({ commit, state }) => {
    commit('setUIFlag', { isFetchingUtilization: true });
    try {
      const response = await assignmentMetricsAPI.getAgentUtilization(
        state.filters
      );
      commit('setAgentUtilization', response.data.agent_utilization || []);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetchingUtilization: false });
    }
  },

  getAssignmentDistribution: async ({ commit, state }) => {
    commit('setUIFlag', { isFetchingDistribution: true });
    try {
      const response = await assignmentMetricsAPI.get(state.filters);
      commit(
        'setAssignmentDistribution',
        response.data.assignment_distribution || {}
      );
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isFetchingDistribution: false });
    }
  },

  exportReport: async ({ commit, state }, type) => {
    commit('setUIFlag', { isExporting: true });
    try {
      const response = await assignmentMetricsAPI.exportReport(
        type,
        state.filters
      );

      // Create download link
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute(
        'download',
        `assignment-${type}-report-${Date.now()}.csv`
      );
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);

      return true;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit('setUIFlag', { isExporting: false });
    }
  },

  setFilters: ({ commit, dispatch }, filters) => {
    commit('setFilters', filters);
    // Refresh all data with new filters
    dispatch('getMetrics');
    dispatch('getAgentHistory');
    dispatch('getPolicyPerformance');
    dispatch('getAgentUtilization');
    dispatch('getAssignmentDistribution');
  },

  refreshAllMetrics: ({ dispatch }) => {
    return Promise.all([
      dispatch('getMetrics'),
      dispatch('getAgentHistory'),
      dispatch('getPolicyPerformance'),
      dispatch('getAgentUtilization'),
      dispatch('getAssignmentDistribution'),
    ]);
  },
};
