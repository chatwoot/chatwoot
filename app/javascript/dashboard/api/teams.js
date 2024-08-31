/* global axios */
// import ApiClient from './ApiClient';
import CacheEnabledApiClient from './CacheEnabledApiClient';

export class TeamsAPI extends CacheEnabledApiClient {
  constructor() {
    super('teams', { accountScoped: true });
  }

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    return 'team';
  }

  // eslint-disable-next-line class-methods-use-this
  extractDataFromResponse(response) {
    return response.data;
  }

  // eslint-disable-next-line class-methods-use-this
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

  getLeader(teamId) {
    return axios.get(`${this.url}/${teamId}/leader`);
  }

  updateLeader(teamId, userId) {
    return axios.patch(`${this.url}/${teamId}/update_leader`, {
      user_id: userId,
    });
  }
}

export default new TeamsAPI();
