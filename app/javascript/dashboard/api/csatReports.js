/* global axios */
import ApiClient from './ApiClient';

class CSATReportsAPI extends ApiClient {
  constructor() {
    super('csat_survey_responses', { accountScoped: true });
  }

  get({
    page,
    from,
    to,
    user_ids,
    inbox_id,
    team_id,
    rating,
    question_id,
    label,
    question,
  } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        since: from,
        until: to,
        sort: '-created_at',
        user_ids,
        inbox_id,
        team_id,
        rating,
        question_id,
        label,
        question,
      },
    });
  }

  getQuestions({ from, to, user_ids, inbox_id, team_id, rating, label, question } = {}) {
    return axios.get(`${this.url}/questions`, {
      params: {
        since: from,
        until: to,
        sort: '-created_at',
        user_ids,
        inbox_id,
        team_id,
        rating,
        label,
        question,
      },
    });
  }

  download({ from, to, user_ids, inbox_id, team_id, rating, label, question } = {}) {
    return axios.get(`${this.url}/download`, {
      params: {
        since: from,
        until: to,
        sort: '-created_at',
        user_ids,
        inbox_id,
        team_id,
        rating,
        label,
        question,
      },
    });
  }

  getMetrics({ from, to, user_ids, inbox_id, team_id, rating, label, question } = {}) {
    // no ratings for metrics
    return axios.get(`${this.url}/metrics`, {
      params: { since: from, until: to, user_ids, inbox_id, team_id, rating, label, question },
    });
  }
}

export default new CSATReportsAPI();
