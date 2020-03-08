/* eslint no-console: 0 */
/* global axios */
import ApiClient from '../ApiClient';

class MessageApi extends ApiClient {
  constructor() {
    super('conversations');
  }

  create({ conversationId, message, private: isPrivate }) {
    return axios.post(`${this.url}/${conversationId}/messages`, {
      message,
      private: isPrivate,
    });
  }

  getPreviousMessages({ conversationId, before }) {
    return axios.get(`${this.url}/${conversationId}/messages`, {
      params: { before },
    });
  }
}

export default new MessageApi();
