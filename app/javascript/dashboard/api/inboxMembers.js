/* global axios */
import ApiClient from './ApiClient';

class InboxMembers extends ApiClient {
  constructor() {
    super('inbox_members', { accountScoped: true });
  }

  update({ inboxId, agentList, teamId }) {
    return axios.patch(this.url, {
      inbox_id: inboxId,
      user_ids: agentList,
      team_id: teamId,
    });
  }
}

export default new InboxMembers();
