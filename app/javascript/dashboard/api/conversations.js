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

  changeInbox(conversationID, inboxID) {
    return axios.patch(`${this.url}/${conversationID}/change_inbox`, {
      inbox_id: inboxID,
    });
  }

  forceTransfer(conversationId) {
    return axios.post(`${this.url}/${conversationId}/force_transfer`);
  }
}

export default new ConversationApi();
