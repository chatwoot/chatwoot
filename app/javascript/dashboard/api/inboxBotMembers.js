/* global axios */
import ApiClient from './ApiClient';

class InboxBotMembers extends ApiClient {
  constructor() {
    super('inbox_bot_members', { accountScoped: true });
  }

  update({ inboxId, agentBotList }) {
    return axios.patch(this.url, {
      inbox_id: inboxId,
      bot_ids: agentBotList,
    });
  }
}

export default new InboxBotMembers();
