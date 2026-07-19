/* global axios */
import ApiClient from './ApiClient';

class InternalChatsAPI extends ApiClient {
  constructor() {
    super('internal_conversations', { accountScoped: true });
  }

  getRooms() {
    return axios.get(this.url);
  }

  getMessages(conversationId, params = {}) {
    return axios.get(`${this.url}/${conversationId}/messages`, { params });
  }

  createMessage(conversationId, content) {
    return axios.post(`${this.url}/${conversationId}/create_message`, {
      content,
    });
  }
}

export default new InternalChatsAPI();
