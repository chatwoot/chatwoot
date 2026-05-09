/* global axios */

import ApiClient from '../ApiClient';

class NotionAPI extends ApiClient {
  constructor() {
    super('integrations/notion', { accountScoped: true });
  }

  getIssueTracker() {
    return axios.get(`${this.url}/issue_tracker`);
  }

  updateIssueTracker(data) {
    return axios.patch(`${this.url}/issue_tracker`, data);
  }

  validateIssueTracker(data) {
    return axios.post(`${this.url}/validate_issue_tracker`, data);
  }
}

export default new NotionAPI();
