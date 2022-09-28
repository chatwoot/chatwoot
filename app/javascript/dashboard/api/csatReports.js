/* global axios */
import ApiClient from './ApiClient';

class CSATReportsAPI extends ApiClient {
  constructor() {
    super('csat_survey_responses', { accountScoped: true });
  }

  get({ page, from, to, user_ids } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        since: from,
        until: to,
        sort: '-created_at',
        user_ids,
      },
    });
  }

  download({ from, to, user_ids } = {}) {
    return axios.get(`${this.url}/download`, {
      params: {
        since: from,
        until: to,
        sort: '-created_at',
        user_ids,
      },
    });
  }

  getMetrics({ from, to, user_ids } = {}) {
    return axios.get(`${this.url}/metrics`, {
      params: { since: from, until: to, user_ids },
    });
  }
}

export default new CSATReportsAPI();
