export const getters = {
  getMetrics: state => state.metrics,
  getOverviewMetrics: state => state.metrics.overview,
  getAgentHistory: state => state.metrics.agentHistory,
  getPolicyPerformance: state => state.metrics.policyPerformance,
  getAgentUtilization: state => state.metrics.agentUtilization,
  getAssignmentDistribution: state => state.metrics.assignmentDistribution,
  getAssignmentTrends: state => state.metrics.assignmentTrends,
  getFilters: state => state.filters,
  getUIFlags: state => state.uiFlags,

  getTopPerformingAgents: state => {
    return [...state.metrics.agentHistory]
      .sort((a, b) => b.assignments_handled - a.assignments_handled)
      .slice(0, 5);
  },

  getTopPerformingPolicies: state => {
    return [...state.metrics.policyPerformance]
      .sort((a, b) => b.success_rate - a.success_rate)
      .slice(0, 5);
  },

  getAverageUtilization: state => {
    const utilization = state.metrics.agentUtilization;
    if (!utilization.length) return 0;

    const totalUtilization = utilization.reduce(
      (sum, agent) => sum + agent.utilization_percentage,
      0
    );
    return (totalUtilization / utilization.length).toFixed(2);
  },

  getCalculatedTrends: state => {
    const history = state.metrics.agentHistory;
    if (!history.length) return [];

    // Group by date and calculate trends
    const trendMap = {};
    history.forEach(entry => {
      const date = entry.date;
      if (!trendMap[date]) {
        trendMap[date] = {
          date,
          total_assignments: 0,
          avg_response_time: 0,
          count: 0,
        };
      }
      trendMap[date].total_assignments += entry.assignments_handled;
      trendMap[date].avg_response_time += entry.avg_response_time;
      trendMap[date].count += 1;
    });

    return Object.values(trendMap).map(trend => ({
      date: trend.date,
      total_assignments: trend.total_assignments,
      avg_response_time: trend.avg_response_time / trend.count,
    }));
  },
};
