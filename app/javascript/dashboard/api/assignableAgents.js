/* global axios */
import ApiClient from './ApiClient';

class AssignableAgents extends ApiClient {
  constructor() {
    super('assignable_agents', { accountScoped: true });
  }

  get(inboxIds, { includeAIAssignees = false } = {}) {
    return axios.get(this.url, {
      params: {
        inbox_ids: inboxIds,
        ...(includeAIAssignees ? { include_ai_assignees: true } : {}),
      },
    });
  }
}

export default new AssignableAgents();
