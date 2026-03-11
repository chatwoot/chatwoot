/* global axios */
// import ApiClient from './ApiClient';
import CacheEnabledApiClient from './CacheEnabledApiClient';

export class TeamsAPI extends CacheEnabledApiClient {
  constructor() {
    super('teams', { accountScoped: true });
  }

  get cacheModelName() {
    return 'team';
  }

  extractDataFromResponse(response) {
    return response.data;
  }

  marshallData(dataToParse) {
    return { data: dataToParse };
  }

  getAgents({ teamId }) {
    return axios.get(`${this.url}/${teamId}/team_members`);
  }

  addAgents({ teamId, agentsList }) {
    return axios.post(`${this.url}/${teamId}/team_members`, {
      user_ids: agentsList,
    });
  }

  updateAgents({ teamId, agentsList }) {
    return axios.patch(`${this.url}/${teamId}/team_members`, {
      user_ids: agentsList,
    });
  }
}

export default new TeamsAPI();
