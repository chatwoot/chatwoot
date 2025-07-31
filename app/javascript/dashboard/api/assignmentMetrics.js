/* global axios */
import ApiClient from './ApiClient';

export class AssignmentMetricsAPI extends ApiClient {
  constructor() {
    super('reports/assignment_metrics', { accountScoped: true });
  }

  // GET /api/v1/accounts/:accountId/reports/assignment_metrics
  get(params = {}) {
    return axios.get(this.url, { params });
  }

  // GET /api/v1/accounts/:accountId/agents/:userId/assignment_history
  getAgentHistory(userId, params = {}) {
    return axios.get(
      `/api/v1/accounts/${this.accountId}/agents/${userId}/assignment_history`,
      { params }
    );
  }

  // Get all agents assignment history
  getAllAgentsHistory(params = {}) {
    return axios.get(this.url, {
      params: { ...params, include_agent_history: true },
    });
  }

  // Get policy performance metrics
  getPolicyPerformance(params = {}) {
    return axios.get(this.url, {
      params: { ...params, include_policy_performance: true },
    });
  }

  // Get agent utilization metrics
  getAgentUtilization(params = {}) {
    return axios.get(this.url, {
      params: { ...params, include_utilization: true },
    });
  }

  // Export report data
  exportReport(type, params = {}) {
    return axios.get(`${this.url}/export`, {
      params: { type, ...params },
      responseType: 'blob',
    });
  }
}

export default new AssignmentMetricsAPI();
