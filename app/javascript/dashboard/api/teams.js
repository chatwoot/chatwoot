/* global axios */
import ApiClient from './ApiClient';

export class TeamsAPI extends ApiClient {
  constructor() {
    super('teams', { accountScoped: true });
  }

  getAgents({ teamId }) {
    return axios.get(`${this.url}/${teamId}/team_members`);
  }

  addAgents({ teamId, agentsList }) {
    return axios.post(`${this.url}/${teamId}/team_members`, {
      user_ids: agentsList,
    });
  }
}

export default new TeamsAPI();
