/* global axios */
import ApiClient from '../ApiClient';

class AlooConversation extends ApiClient {
  constructor() {
    super('aloo/assistants', { accountScoped: true });
  }

  getConversations(assistantId, { page = 1 } = {}) {
    return axios.get(`${this.url}/${assistantId}/conversations`, {
      params: { page },
    });
  }
}

export default new AlooConversation();
