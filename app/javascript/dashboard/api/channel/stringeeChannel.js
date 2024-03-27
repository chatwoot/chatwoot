/* global axios */
import ApiClient from '../ApiClient';

class StringeeChannel extends ApiClient {
  constructor() {
    super('channels/stringee_channels', { accountScoped: true });
  }

  updateAgents({ inboxId, agentList }) {
    return axios.patch(`${this.url}/update_agents`, {
      inbox_id: inboxId,
      user_ids: agentList,
    });
  }
}

export default new StringeeChannel();
