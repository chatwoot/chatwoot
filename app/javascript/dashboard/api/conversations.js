/* global axios */
import ApiClient from './ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations');
  }

  getLabels(conversationID) {
    return axios.get(`${this.url}/${conversationID}/labels`);
  }

  createLabels(conversationID) {
    return axios.get(`${this.url}/${conversationID}/labels`);
  }
}

export default new ConversationApi();
