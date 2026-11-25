/* global axios */
import ApiClient from './ApiClient';

class SummaryReportsAPI extends ApiClient {
  constructor() {
    super('summary_reports', { accountScoped: true, apiVersion: 'v2' });
  }

  getTeamReports({ since, until, businessHours } = {}) {
    return axios.get(`${this.url}/team`, {
      params: {
        since,
        until,
        business_hours: businessHours,
      },
    });
  }

  getAgentReports({ since, until, businessHours, inboxId } = {}) {
    return axios.get(`${this.url}/agent`, {
      params: {
        since,
        until,
        business_hours: businessHours,
        inbox_id: inboxId,
      },
    });
  }

  getHandledConversations({ since, until, inboxId, signal } = {}) {
    return axios.get(`${this.url}/handled_conversations`, {
      signal,
      params: { since, until, inbox_id: inboxId },
    });
  }

  getInboxReports({ since, until, businessHours, userId } = {}) {
    return axios.get(`${this.url}/inbox`, {
      params: {
        since,
        until,
        business_hours: businessHours,
        user_id: userId,
      },
    });
  }

  getLabelReports({ since, until, businessHours } = {}) {
    return axios.get(`${this.url}/label`, {
      params: {
        since,
        until,
        business_hours: businessHours,
      },
    });
  }
}

export default new SummaryReportsAPI();
