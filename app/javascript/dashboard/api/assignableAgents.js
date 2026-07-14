/* global axios */
import ApiClient from './ApiClient';

class AssignableAgents extends ApiClient {
  constructor() {
    super('assignable_agents', { accountScoped: true });
  }

  get(inboxIds, { includeAgentBots = false } = {}) {
    return axios.get(this.url, {
      params: {
        inbox_ids: inboxIds,
        ...(includeAgentBots ? { include_agent_bots: true } : {}),
      },
    });
  }
}

export default new AssignableAgents();
