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

  getAgentReports({ since, until, businessHours } = {}) {
    return axios.get(`${this.url}/agent`, {
      params: {
        since,
        until,
        business_hours: businessHours,
      },
    });
  }

  getInboxReports({ since, until, businessHours } = {}) {
    return axios.get(`${this.url}/inbox`, {
      params: {
        since,
        until,
        business_hours: businessHours,
      },
    });
  }
}

export default new SummaryReportsAPI();
