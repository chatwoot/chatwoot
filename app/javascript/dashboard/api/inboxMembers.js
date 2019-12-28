/* global axios */
import ApiClient from './ApiClient';

class InboxMembers extends ApiClient {
  constructor() {
    super('inbox_members');
  }

  create({ inboxId, agentList }) {
    return axios.post(this.url, {
      inbox_id: inboxId,
      user_ids: agentList,
    });
  }
}

export default new InboxMembers();
