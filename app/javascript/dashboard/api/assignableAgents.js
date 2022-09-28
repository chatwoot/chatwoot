/* global axios */
import ApiClient from './ApiClient';

class AssignableAgents extends ApiClient {
  constructor() {
    super('assignable_agents', { accountScoped: true });
  }

  get(inboxIds) {
    return axios.get(this.url, {
      params: { inbox_ids: inboxIds },
    });
  }
}

export default new AssignableAgents();
