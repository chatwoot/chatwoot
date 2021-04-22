/* global axios */
import ApiClient from './ApiClient';

class Inboxes extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  getAssignableAgents(inboxId) {
    return axios.get(`${this.url}/${inboxId}/assignable_agents`);
  }
}

export default new Inboxes();
