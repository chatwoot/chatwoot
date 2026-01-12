/* global axios */
import ApiClient from './ApiClient';

class CSATReportsAPI extends ApiClient {
  constructor() {
    super('csat_survey_responses', { accountScoped: true });
  }

  get({ page, from, to, user_ids, inbox_ids, team_ids, rating } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        since: from,
        until: to,
        sort: '-created_at',
        user_ids,
        inbox_ids,
        team_ids,
        rating,
      },
    });
  }

  download({ from, to, user_ids, inbox_ids, team_ids, rating } = {}) {
    return axios.get(`${this.url}/download`, {
      params: {
        since: from,
        until: to,
        sort: '-created_at',
        user_ids,
        inbox_ids,
        team_ids,
        rating,
      },
    });
  }

  getMetrics({ from, to, user_ids, inbox_ids, team_ids, rating } = {}) {
    // no ratings for metrics
    return axios.get(`${this.url}/metrics`, {
      params: { since: from, until: to, user_ids, inbox_ids, team_ids, rating },
    });
  }
}

export default new CSATReportsAPI();
