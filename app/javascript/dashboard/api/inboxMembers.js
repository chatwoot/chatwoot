/* global axios */
import ApiClient from './ApiClient';

class InboxMembers extends ApiClient {
  constructor() {
    super('inbox_members', { accountScoped: true });
  }

  update({ inboxId, agentList }) {
    return axios.patch(this.url, {
      inbox_id: inboxId,
      user_ids: agentList,
    });
  }

  addInboxesToAgent({ inboxIds, userId }) {
    return axios.post(this.url, {
      inbox_ids: inboxIds,
      user_ids: [userId], // can modify to accept multiple agents
    });
  }
}

export default new InboxMembers();
