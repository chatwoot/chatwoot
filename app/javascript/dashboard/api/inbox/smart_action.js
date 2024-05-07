/* eslint no-console: 0 */
/* global axios */
import ApiClient from '../ApiClient';

class SmartActionApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getSmartActions(conversationId, messageId) {
    return axios.get(`${this.url}/${conversationId}/smart_actions`, {
        params: {
          message_id: messageId
        }
    });
  }
}

export default new SmartActionApi();
