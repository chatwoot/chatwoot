/* global axios */
import ApiClient from './ApiClient';

class ReportsAPI extends ApiClient {
  constructor() {
    super('reports', { accountScoped: true, apiVersion: 'v2' });
  }

  getReports(metric, since, until, type = 'account', id) {
    return axios.get(`${this.url}`, {
      params: { metric, since, until, type, id },
    });
  }

  getSummary(since, until, type = 'account', id) {
    return axios.get(`${this.url}/summary`, {
      params: { since, until, type, id },
    });
  }

  getAgentReports(since, until) {
    return axios.get(`${this.url}/agents`, {
      params: { since, until },
    });
  }

  getLabelReports(since, until) {
    return axios.get(`${this.url}/labels`, {
      params: { since, until },
    });
  }

  getInboxReports(since, until) {
    return axios.get(`${this.url}/inboxes`, {
      params: { since, until },
    });
  }
}

export default new ReportsAPI();
