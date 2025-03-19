/* global axios */
import ApiClient from './ApiClient';

class InboxMembers extends ApiClient {
  constructor() {
    super('inbox_members', { accountScoped: true });
  }

  update({ inboxId, agentList, allowedAgents }) {
    return axios.patch(this.url, {
      inbox_id: inboxId,
      user_ids: agentList,
      allowed_user_ids: allowedAgents,
    });
  }
}

export default new InboxMembers();
