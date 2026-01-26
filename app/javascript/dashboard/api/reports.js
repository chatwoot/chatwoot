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

  getAllMetricsReports({
    from: since,
    to: until,
    businessHours,
    format = 'csv',
    userIds,
    inboxIds,
    teamIds,
  } = {}) {
    const params = {
      since,
      until,
      business_hours: businessHours,
      timezone_offset: getTimeOffset(),
    };

    if (userIds && userIds.length > 0) {
      params.user_ids = userIds;
    }
    if (inboxIds && inboxIds.length > 0) {
      params.inbox_ids = inboxIds;
    }
    if (teamIds && teamIds.length > 0) {
      params.team_ids = teamIds;
    }

    return axios.get(
      `${this.url}/all_conversation_metrics_download.${format}`,
      {
        params,
        responseType: format === 'xlsx' ? 'blob' : undefined,
        paramsSerializer: requestParams => {
          const searchParams = new URLSearchParams();
          Object.keys(requestParams).forEach(key => {
            const value = requestParams[key];
            if (Array.isArray(value)) {
              value.forEach(item => searchParams.append(`${key}[]`, item));
            } else if (value !== undefined && value !== null) {
              searchParams.append(key, value);
            }
          });
          return searchParams.toString();
        },
      }
    );
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

  getConversationsSummaryReports({ from: since, to: until, businessHours }) {
    return axios.get(`${this.url}/conversations_summary`, {
      params: { since, until, business_hours: businessHours },
    });
  }

  getConversationTrafficCSV({ daysBefore = 6 } = {}) {
    return axios.get(`${this.url}/conversation_traffic`, {
      params: { timezone_offset: getTimeOffset(), days_before: daysBefore },
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
}

export default new ReportsAPI();
