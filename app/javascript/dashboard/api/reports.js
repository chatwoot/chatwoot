/* global axios */
import ApiClient from './ApiClient';

class ReportsAPI extends ApiClient {
  constructor() {
    super('reports', { accountScoped: true, apiVersion: 'v2' });
  }

  getAccountReports(metric, since, until) {
    return axios.get(`${this.url}/account`, {
      params: { metric, since, until },
    });
  }

  getAccountSummary(since, until) {
    return axios.get(`${this.url}/account_summary`, {
      params: { since, until },
    });
  }
}

export default new ReportsAPI();
