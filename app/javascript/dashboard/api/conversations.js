/* global axios */
import ApiClient from './ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getLabels(conversationID) {
    return axios.get(`${this.url}/${conversationID}/labels`);
  }

  updateLabels(conversationID, labels) {
    return axios.post(`${this.url}/${conversationID}/labels`, { labels });
  }

  getSummary(conversationID, forceRefresh = false) {
    return axios.get('/api/v1/summary', {
      params: {
        conversation_id: conversationID,
        force_refresh: forceRefresh
      },
    });
  }
}

export default new ConversationApi();
