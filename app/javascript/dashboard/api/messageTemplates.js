/* global axios */
import ApiClient from './ApiClient';

class MessageTemplatesAPI extends ApiClient {
  constructor() {
    super('message_templates', { accountScoped: true });
  }

  sync(inboxId) {
    return axios.post(`${this.url}/sync`, { inbox_id: inboxId });
  }
}

export default new MessageTemplatesAPI();
