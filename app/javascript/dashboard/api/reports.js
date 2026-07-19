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
      params: {
        type,
        page,
      },
    });
  }

  getAgentReports({ from: since, to: until, businessHours, exportFormat }) {
    return axios.get(`${this.url}/agents`, {
      params: {
        since,
        until,
        business_hours: businessHours,
        export_format: exportFormat,
      },
      responseType: exportFormat === 'xlsx' ? 'blob' : 'text',
    });
  }

  getConversationsSummaryReports({
    from: since,
    to: until,
    businessHours,
    exportFormat,
  }) {
    return axios.get(`${this.url}/conversations_summary`, {
      params: {
        since,
        until,
        business_hours: businessHours,
        export_format: exportFormat,
      },
      responseType: exportFormat === 'xlsx' ? 'blob' : 'text',
    });
  }

  getConversationTrafficCSV({ daysBefore = 6, exportFormat } = {}) {
    return axios.get(`${this.url}/conversation_traffic`, {
      params: {
        timezone_offset: getTimeOffset(),
        days_before: daysBefore,
        export_format: exportFormat,
      },
      responseType: exportFormat === 'xlsx' ? 'blob' : 'text',
    });
  }

  getLabelReports({ from: since, to: until, businessHours, exportFormat }) {
    return axios.get(`${this.url}/labels`, {
      params: {
        since,
        until,
        business_hours: businessHours,
        export_format: exportFormat,
      },
      responseType: exportFormat === 'xlsx' ? 'blob' : 'text',
    });
  }

  getInboxReports({ from: since, to: until, businessHours, exportFormat }) {
    return axios.get(`${this.url}/inboxes`, {
      params: {
        since,
        until,
        business_hours: businessHours,
        export_format: exportFormat,
      },
      responseType: exportFormat === 'xlsx' ? 'blob' : 'text',
    });
  }

  getTeamReports({ from: since, to: until, businessHours, exportFormat }) {
    return axios.get(`${this.url}/teams`, {
      params: {
        since,
        until,
        business_hours: businessHours,
        export_format: exportFormat,
      },
      responseType: exportFormat === 'xlsx' ? 'blob' : 'text',
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
}

export default new ReportsAPI();
