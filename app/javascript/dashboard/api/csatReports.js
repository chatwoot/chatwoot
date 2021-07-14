/* global axios */
import ApiClient from './ApiClient';

class CSATReportsAPI extends ApiClient {
  constructor() {
    super('csat_survey_responses', { accountScoped: true });
  }

  get({ page } = {}) {
    return axios.get(this.url, { params: { page } });
  }

  getMetrics() {
    return axios.get(`${this.url}/metrics`);
  }
}

export default new CSATReportsAPI();
