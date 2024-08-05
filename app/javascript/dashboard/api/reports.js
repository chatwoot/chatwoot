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
    agentsIds = [],
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
        agents_ids: agentsIds,
      },
    });
  }

  getSummary(
    since,
    until,
    // eslint-disable-next-line default-param-last
    type = 'account',
    id,
    groupBy,
    businessHours,
    agentsIds = []
  ) {
    return axios.get(`${this.url}/summary`, {
      params: {
        since,
        until,
        type,
        id,
        group_by: groupBy,
        business_hours: businessHours,
        timezone_offset: getTimeOffset(),
        agents_ids: agentsIds,
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

  getTriggersMetricsReport({ from: since, to: until, businessHours }) {
    return axios.get(`${this.url}/triggers`, {
      params: { since, until, business_hours: businessHours },
    });
  }

  getInvoicesReport({ from: since, to: until, businessHours }) {
    return axios.get(`${this.url}/invoices`, {
      params: { since, until, business_hours: businessHours },
    });
  }

  getTicketsReport({ from: since, to: until, businessHours }) {
    return axios.get(`${this.url}/tickets`, {
      params: { since, until, business_hours: businessHours },
    });
  }

  getTicketsSummaryReport({ from: since, to: until }) {
    return axios.get(`${this.url}/summary_tickets`, {
      params: { since, until, type: 'account' },
    });
  }
}

export default new ReportsAPI();
