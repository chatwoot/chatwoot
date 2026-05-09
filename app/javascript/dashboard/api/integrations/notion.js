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

  createIssue(data) {
    return axios.post(`${this.url}/create_issue`, data);
  }

  getLinkedIssues(conversationId) {
    return axios.get(
      `${this.url}/linked_issues?conversation_id=${conversationId}`
    );
  }
}

export default new NotionAPI();
