import ApiClient from './ApiClient';

class Inboxes extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  getCampaigns(inboxId) {
    return this.axios.get(`${this.url}/${inboxId}/campaigns`);
  }

  deleteInboxAvatar(inboxId) {
    return this.axios.delete(`${this.url}/${inboxId}/avatar`);
  }
}

export default new Inboxes();
