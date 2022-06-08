import ApiClient from './ApiClient';

class InboxMembers extends ApiClient {
  constructor() {
    super('inbox_members', { accountScoped: true });
  }

  update({ inboxId, agentList }) {
    return this.axios.patch(this.url, {
      inbox_id: inboxId,
      user_ids: agentList,
    });
  }
}

export default new InboxMembers();
