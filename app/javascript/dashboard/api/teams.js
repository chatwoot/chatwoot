import ApiClient from './ApiClient';

export class TeamsAPI extends ApiClient {
  constructor() {
    super('teams', { accountScoped: true });
  }

  getAgents({ teamId }) {
    return this.axios.get(`${this.url}/${teamId}/team_members`);
  }

  addAgents({ teamId, agentsList }) {
    return this.axios.post(`${this.url}/${teamId}/team_members`, {
      user_ids: agentsList,
    });
  }

  updateAgents({ teamId, agentsList }) {
    return this.axios.patch(`${this.url}/${teamId}/team_members`, {
      user_ids: agentsList,
    });
  }
}

export default new TeamsAPI();
