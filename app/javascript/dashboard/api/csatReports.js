/* global axios */
import ApiClient from './ApiClient';

class CSATReportsAPI extends ApiClient {
  constructor() {
    super('csat_survey_responses', { accountScoped: true });
  }

  get({ page, from, to, user_ids, inbox_id } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        since: from,
        until: to,
        sort: '-created_at',
        user_ids,
        inbox_id,
      },
    });
  }

  download({ from, to, user_ids, inbox_id } = {}) {
    return axios.get(`${this.url}/download`, {
      params: {
        since: from,
        until: to,
        sort: '-created_at',
        user_ids,
        inbox_id,
      },
    });
  }

  getMetrics({ from, to, user_ids, inbox_id } = {}) {
    return axios.get(`${this.url}/metrics`, {
      params: { since: from, until: to, user_ids, inbox_id },
    });
  }
}

export default new CSATReportsAPI();
