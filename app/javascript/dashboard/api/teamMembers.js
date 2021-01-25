/* global axios */
import ApiClient from './ApiClient';

class TeamMembers extends ApiClient {
  constructor() {
    super('team_members', { accountScoped: true });
  }

  create({ teamId, agentList }) {
    return axios.post(this.url, {
      team_id: teamId,
      user_ids: agentList,
    });
  }
}

export default new TeamMembers();
