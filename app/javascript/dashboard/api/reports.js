/* global axios */
import ApiClient from './ApiClient';

class ReportsAPI extends ApiClient {
  constructor() {
    super('reports', { accountScoped: true, apiVersion: 'v2' });
  }

  getAccountReports(metric, since, until) {
    return axios.get(`${this.url}`, {
      params: { metric, since, until, type: 'account' },
    });
  }

  getAccountSummary(since, until) {
    return axios.get(`${this.url}/summary`, {
      params: { since, until, type: 'account' },
    });
  }

  getAgentReports(since, until) {
    return axios.get(`${this.url}/agents`, {
      params: { since, until },
    });
  }
}

export default new ReportsAPI();
