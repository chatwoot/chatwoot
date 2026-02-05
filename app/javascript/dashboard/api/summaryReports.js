/* global axios */
import ApiClient from './ApiClient';

class SummaryReportsAPI extends ApiClient {
  constructor() {
    super('summary_reports', { accountScoped: true, apiVersion: 'v2' });
  }

  getTeamReports({
    since,
    until,
    businessHours,
    userIds,
    inboxIds,
    teamIds,
  } = {}) {
    const params = {
      since,
      until,
      business_hours: businessHours,
    };

    if (userIds && userIds.length > 0) {
      params['user_ids[]'] = userIds;
    }

    if (inboxIds && inboxIds.length > 0) {
      params['inbox_ids[]'] = inboxIds;
    }

    if (teamIds && teamIds.length > 0) {
      params['team_ids[]'] = teamIds;
    }

    return axios.get(`${this.url}/team`, { params });
  }

  getAgentReports({
    since,
    until,
    businessHours,
    userIds,
    inboxIds,
    teamIds,
  } = {}) {
    const params = {
      since,
      until,
      business_hours: businessHours,
    };

    if (userIds && userIds.length > 0) {
      params['user_ids[]'] = userIds;
    }

    if (inboxIds && inboxIds.length > 0) {
      params['inbox_ids[]'] = inboxIds;
    }

    if (teamIds && teamIds.length > 0) {
      params['team_ids[]'] = teamIds;
    }

    return axios.get(`${this.url}/agent`, { params });
  }

  getInboxReports({
    since,
    until,
    businessHours,
    userIds,
    inboxIds,
    teamIds,
  } = {}) {
    const params = {
      since,
      until,
      business_hours: businessHours,
    };

    if (userIds && userIds.length > 0) {
      params['user_ids[]'] = userIds;
    }

    if (inboxIds && inboxIds.length > 0) {
      params['inbox_ids[]'] = inboxIds;
    }

    if (teamIds && teamIds.length > 0) {
      params['team_ids[]'] = teamIds;
    }

    return axios.get(`${this.url}/inbox`, { params });
  }

  getLabelReports({
    since,
    until,
    businessHours,
    userIds,
    inboxIds,
    teamIds,
  } = {}) {
    const params = {
      since,
      until,
      business_hours: businessHours,
    };

    if (userIds && userIds.length > 0) {
      params['user_ids[]'] = userIds;
    }

    if (inboxIds && inboxIds.length > 0) {
      params['inbox_ids[]'] = inboxIds;
    }

    if (teamIds && teamIds.length > 0) {
      params['team_ids[]'] = teamIds;
    }

    return axios.get(`${this.url}/label`, { params });
  }

  getBotSummaryReports({ since, until, businessHours, inboxId } = {}) {
    const params = {
      since,
      until,
      business_hours: businessHours,
    };

    if (inboxId && inboxId.length > 0) {
      params['inbox_ids[]'] = inboxId;
    }

    return axios.get(`${this.url}/bot`, {
      params,
    });
  }
}

export default new SummaryReportsAPI();
