/* global axios */
import ApiClient from './ApiClient';

class InboxHealthAPI extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  getHealthStatus(inboxId, { signal } = {}) {
    return axios.get(`${this.url}/${inboxId}/health`, { signal });
  }

  applyDisplayName(inboxId, displayName) {
    return axios.post(`${this.url}/${inboxId}/apply_display_name`, {
      display_name: displayName,
    });
  }

  registerWebhook(inboxId) {
    return axios.post(`${this.url}/${inboxId}/register_webhook`);
  }
}

export default new InboxHealthAPI();
