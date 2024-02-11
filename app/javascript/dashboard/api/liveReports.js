/* global axios */
import ApiClient from './ApiClient';

class LiveReportsAPI extends ApiClient {
  constructor() {
    super('live_reports', { accountScoped: true, apiVersion: 'v2' });
  }

  getConversationMetric() {
    return axios.get(`${this.url}/conversation_metrics`);
  }

  getGroupedConversations({ groupBy } = { groupBy: 'assignee_id' }) {
    return axios.get(`${this.url}/grouped_conversation_metrics`, {
      params: { group_by: groupBy },
    });
  }
}

export default new LiveReportsAPI();
