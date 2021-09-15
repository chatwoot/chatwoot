/* global axios */
import ApiClient from './ApiClient';

class Inboxes extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  getAssignableAgents(inboxId) {
    return axios.get(`${this.url}/${inboxId}/assignable_agents`);
  }

  getCampaigns(inboxId) {
    return axios.get(`${this.url}/${inboxId}/campaigns`);
  }

  deleteInboxAvatar(inboxId) {
    return axios.delete(`${this.url}/${inboxId}/avatar`);
  }
}

export default new Inboxes();
