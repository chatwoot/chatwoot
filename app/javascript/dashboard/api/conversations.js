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

  async createInstagramDmConversation(payload) {
    const url = `/api/v1/accounts/${this.accountIdFromRoute}/create_instagram_dm_conversations`;

    return axios.post(url, payload, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }
}

export default new ConversationApi();
