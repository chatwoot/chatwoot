/* global axios */
import ApiClient from './ApiClient';

class InboxHealthAPI extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  getHealthStatus(inboxId) {
    return axios.get(`${this.url}/${inboxId}/health`);
  }
}

export default new InboxHealthAPI();
