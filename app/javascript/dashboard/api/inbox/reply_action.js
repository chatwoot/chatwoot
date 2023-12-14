/* eslint no-console: 0 */
/* global axios */
import ApiClient from '../ApiClient';

class ReplyActionApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  get(conversationId) {
    return axios.get(`${this.url}/${conversationId}/reply_action`);
  }

  update({ conversationId, message }) {
    return axios.put(`${this.url}/${conversationId}/reply_action`, {
      message,
    });
  }

  delete(conversationId) {
    return axios.delete(`${this.url}/${conversationId}/reply_action`);
  }
}

export default new ReplyActionApi();
