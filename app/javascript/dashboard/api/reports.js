/* global axios */
import ApiClient from './ApiClient';

const getTimeOffset = () => -new Date().getTimezoneOffset() / 60;

class ReportsAPI extends ApiClient {
  constructor() {
    super('reports', { accountScoped: true, apiVersion: 'v2' });
  }

  getReports({
    metric,
    from,
    to,
    type = 'account',
    id,
    groupBy,
    businessHours,
  }) {
    return axios.get(`${this.url}`, {
      params: {
        metric,
        since: from,
        until: to,
        type,
        id,
        group_by: groupBy,
        business_hours: businessHours,
        timezone_offset: getTimeOffset(),
      },
    });
  }

  // eslint-disable-next-line default-param-last
  getSummary(since, until, type = 'account', id, groupBy, businessHours) {
    return axios.get(`${this.url}/summary`, {
      params: {
        since,
        until,
        type,
        id,
        group_by: groupBy,
        business_hours: businessHours,
        timezone_offset: getTimeOffset(),
      },
    });
  }

  getConversationMetric(type = 'account', page = 1) {
    return axios.get(`${this.url}/conversations`, {
      params: { type, page },
    });
  }

  getConversationsSummaryReports({
    from: since,
    to: until,
    businessHours,
    format = 'csv',
  }) {
    return axios.get(`${this.url}/conversations_summary.${format}`, {
      params: { since, until, business_hours: businessHours },
      responseType: format === 'xlsx' ? 'blob' : undefined,
    });
  }

  getBotMetrics({ from, to } = {}) {
    return axios.get(`${this.url}/bot_metrics`, {
      params: { since: from, until: to },
    });
  }

  getBotSummary({ from, to, groupBy, businessHours } = {}) {
    return axios.get(`${this.url}/bot_summary`, {
      params: {
        since: from,
        until: to,
        type: 'account',
        group_by: groupBy,
        business_hours: businessHours,
      },
    });
  }

  getAgentReports({ from: since, to: until, businessHours, format = 'csv' }) {
    return axios.get(`${this.url}/agents.${format}`, {
      params: {
        since,
        until,
        business_hours: businessHours,
      },
      responseType: format === 'xlsx' ? 'blob' : undefined,
    });
  }

  getConversationTrafficReports({ daysBefore = 6, format = 'csv' } = {}) {
    return axios.get(`${this.url}/conversation_traffic.${format}`, {
      params: {
        timezone_offset: getTimeOffset(),
        days_before: daysBefore,
      },
      responseType: format === 'xlsx' ? 'blob' : undefined,
    });
  }

  getLabelReports({ from: since, to: until, businessHours, format = 'csv' }) {
    return axios.get(`${this.url}/labels.${format}`, {
      params: {
        since,
        until,
        business_hours: businessHours,
      },
      responseType: format === 'xlsx' ? 'blob' : undefined,
    });
  }

  getInboxReports({ from: since, to: until, businessHours, format = 'csv' }) {
    return axios.get(`${this.url}/inboxes.${format}`, {
      params: {
        since,
        until,
        business_hours: businessHours,
      },
      responseType: format === 'xlsx' ? 'blob' : undefined,
    });
  }

  getTeamReports({ from: since, to: until, businessHours, format = 'csv' }) {
    return axios.get(`${this.url}/teams.${format}`, {
      params: {
        since,
        until,
        business_hours: businessHours,
      },
      responseType: format === 'xlsx' ? 'blob' : undefined,
    });
  }
}

export default new ReportsAPI();
