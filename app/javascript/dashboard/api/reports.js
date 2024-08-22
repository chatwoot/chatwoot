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

  getAgentReports({ from: since, to: until, businessHours }) {
    return axios.get(`${this.url}/agents`, {
      params: { since, until, business_hours: businessHours },
    });
  }

  getConversationTrafficCSV() {
    return axios.get(`${this.url}/conversation_traffic`, {
      params: { timezone_offset: getTimeOffset() },
    });
  }

  getLabelReports({ from: since, to: until, businessHours }) {
    return axios.get(`${this.url}/labels`, {
      params: { since, until, business_hours: businessHours },
    });
  }

  getInboxReports({ from: since, to: until, businessHours }) {
    return axios.get(`${this.url}/inboxes`, {
      params: { since, until, business_hours: businessHours },
    });
  }

  getTeamReports({ from: since, to: until, businessHours }) {
    return axios.get(`${this.url}/teams`, {
      params: { since, until, business_hours: businessHours },
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

  getTemplateSummary({ from, to, groupBy, businessHours, id, channelId } = {}) {
    return axios.get(`${this.url}/template_summary`, {
      params: {
        since: from,
        until: to,
        group_by: groupBy,
        business_hours: businessHours,
        type: 'template',
        id: id,
        channel_id: channelId,
      },
    });
  }

  getTemplateCsv({ from, to, groupBy, businessHours, summary }) {
    return axios.get(`${this.url}/template_csv`, {
      params: {
        since: from,
        until: to,
        type: 'template',
        group_by: groupBy,
        business_hours: businessHours,
        timezone_offset: getTimeOffset(),
        summary_data: summary,
      },
    });
  }

  getTemplateReports({
    metric,
    from,
    to,
    id,
    groupBy,
    businessHours,
    channelId,
  }) {
    return axios.get(`${this.url}/template`, {
      params: {
        metric,
        since: from,
        until: to,
        type: 'template',
        id,
        group_by: groupBy,
        business_hours: businessHours,
        channel_id: channelId,
        timezone_offset: getTimeOffset(),
      },
    });
  }
}

export default new ReportsAPI();
