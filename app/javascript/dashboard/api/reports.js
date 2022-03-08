/* global axios */
import ApiClient from './ApiClient';

const getTimeOffset = () => -new Date().getTimezoneOffset() / 60;

class ReportsAPI extends ApiClient {
  constructor() {
    super('reports', { accountScoped: true, apiVersion: 'v2' });
  }

  getReports(metric, since, until, type = 'account', id, group_by) {
    return axios.get(`${this.url}`, {
      params: {
        metric,
        since,
        until,
        type,
        id,
        group_by,
        timezone_offset: getTimeOffset(),
      },
    });
  }

  getSummary(
    current_since,
    current_until,
    previous_since,
    previous_until,
    type = 'account',
    id,
    group_by
  ) {
    return axios.get(`${this.url}/summary`, {
      params: {
        current_since,
        current_until,
        previous_since,
        previous_until,
        type,
        id,
        group_by,
      },
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

  getTeamReports(since, until) {
    return axios.get(`${this.url}/teams`, {
      params: { since, until },
    });
  }
}

export default new ReportsAPI();
