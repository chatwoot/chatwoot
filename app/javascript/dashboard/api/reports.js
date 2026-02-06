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
    inboxIds,
  }) {
    const params = {
      metric,
      since: from,
      until: to,
      type,
      id,
      group_by: groupBy,
      business_hours: businessHours,
      timezone_offset: getTimeOffset(),
    };

    if (inboxIds && inboxIds.length > 0) {
      params['inbox_ids[]'] = inboxIds;
    }

    return axios.get(`${this.url}`, { params });
  }

  getSummary(since, until, type, id, groupBy, businessHours, inboxIds) {
    const params = {
      since,
      until,
      type: type || 'account',
      id,
      group_by: groupBy,
      business_hours: businessHours,
      timezone_offset: getTimeOffset(),
    };

    if (inboxIds && inboxIds.length > 0) {
      params['inbox_ids[]'] = inboxIds;
    }

    return axios.get(`${this.url}/summary`, { params });
  }

  getAllMetricsReports({
    from: since,
    to: until,
    businessHours,
    format = 'csv',
    userIds,
    inboxIds,
    teamIds,
    sendEmail = false,
    email,
  } = {}) {
    const params = {
      since,
      until,
      business_hours: businessHours,
      timezone_offset: getTimeOffset(),
      send_email: sendEmail,
    };

    if (email) {
      params.email = email;
    }

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
        responseType: sendEmail ? 'json' : 'blob',
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

  getBotMetrics({ from, to, inboxId } = {}) {
    const params = { since: from, until: to };

    if (inboxId && inboxId.length > 0) {
      params['inbox_ids[]'] = inboxId;
    }

    return axios.get(`${this.url}/bot_metrics`, { params });
  }

  getAgentActivityCSV({
    since: since,
    until: until,
    teamIds = [],
    userIds = [],
    inboxIds = [],
    hideInactive = false,
    timezoneOffset = getTimeOffset(),
  } = {}) {
    return axios.get(`${this.url}/agent_activity`, {
      params: {
        since,
        until,
        team_ids: teamIds,
        user_ids: userIds,
        inbox_ids: inboxIds,
        hide_inactive: hideInactive,
        timezone_offset: timezoneOffset,
      },
      responseType: 'blob',
    });
  }

  getAgentActivity({
    since,
    until,
    teamIds = [],
    userIds = [],
    inboxIds = [],
    hideInactive = false,
    timezoneOffset = getTimeOffset(),
  } = {}) {
    return axios.get(`${this.url}/agent_activity`, {
      params: {
        since,
        until,
        team_ids: teamIds,
        user_ids: userIds,
        inbox_ids: inboxIds,
        hide_inactive: hideInactive,
        timezone_offset: timezoneOffset,
      },
    });
  }

  getBotSummary({ from, to, groupBy, businessHours, inboxId } = {}) {
    const params = {
      since: from,
      until: to,
      type: 'account',
      group_by: groupBy,
      business_hours: businessHours,
    };

    if (inboxId && inboxId.length > 0) {
      params['inbox_ids[]'] = inboxId;
    }

    return axios.get(`${this.url}/bot_summary`, { params });
  }

  getOverviewReports({
    from: since,
    to: until,
    businessHours,
    format = 'csv',
  }) {
    return axios.get(`${this.url}/overview_summary.${format}`, {
      params: {
        since,
        until,
        business_hours: businessHours,
        timezone_offset: getTimeOffset(),
      },
      responseType: format === 'xlsx' ? 'blob' : undefined,
    });
  }

  getBotReports({
    from: since,
    to: until,
    groupBy,
    businessHours,
    format = 'csv',
    inboxId,
  }) {
    const params = {
      since,
      until,
      group_by: groupBy,
      business_hours: businessHours,
      timezone_offset: getTimeOffset(),
    };

    if (inboxId && inboxId.length > 0) {
      params['inbox_ids[]'] = inboxId;
    }

    return axios.get(`${this.url}/bot_summary_download.${format}`, {
      params,
      responseType: format === 'xlsx' ? 'blob' : undefined,
    });
  }

  getAgentReports({
    from: since,
    to: until,
    businessHours,
    format = 'csv',
    userIds,
    inboxIds,
    teamIds,
    labelIds,
    timeSince,
    timeUntil,
  }) {
    const params = {
      since,
      until,
      business_hours: businessHours,
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
    if (labelIds && labelIds.length > 0) {
      params.label_ids = labelIds;
    }
    if (timeSince) {
      params.time_since = timeSince;
    }
    if (timeUntil) {
      params.time_until = timeUntil;
    }

    return axios.get(`${this.url}/agents.${format}`, {
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

  getLabelReports({
    from: since,
    to: until,
    businessHours,
    format = 'csv',
    userIds,
    inboxIds,
    teamIds,
    labelIds,
    timeSince,
    timeUntil,
  }) {
    const params = {
      since,
      until,
      business_hours: businessHours,
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
    if (labelIds && labelIds.length > 0) {
      params.label_ids = labelIds;
    }
    if (timeSince) {
      params.time_since = timeSince;
    }
    if (timeUntil) {
      params.time_until = timeUntil;
    }

    return axios.get(`${this.url}/labels.${format}`, {
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
    });
  }

  getInboxReports({
    from: since,
    to: until,
    businessHours,
    format = 'csv',
    userIds,
    inboxIds,
    teamIds,
    labelIds,
    timeSince,
    timeUntil,
  }) {
    const params = {
      since,
      until,
      business_hours: businessHours,
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
    if (labelIds && labelIds.length > 0) {
      params.label_ids = labelIds;
    }
    if (timeSince) {
      params.time_since = timeSince;
    }
    if (timeUntil) {
      params.time_until = timeUntil;
    }

    return axios.get(`${this.url}/inboxes.${format}`, {
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
    });
  }

  getTeamReports({
    from: since,
    to: until,
    businessHours,
    format = 'csv',
    userIds,
    inboxIds,
    teamIds,
    labelIds,
    timeSince,
    timeUntil,
  }) {
    const params = {
      since,
      until,
      business_hours: businessHours,
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
    if (labelIds && labelIds.length > 0) {
      params.label_ids = labelIds;
    }
    if (timeSince) {
      params.time_since = timeSince;
    }
    if (timeUntil) {
      params.time_until = timeUntil;
    }

    return axios.get(`${this.url}/teams.${format}`, {
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
    });
  }
}

export default new ReportsAPI();
