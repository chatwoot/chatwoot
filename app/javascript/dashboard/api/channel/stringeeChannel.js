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

  channelNumbers() {
    return axios.get(`${this.url}`);
  }

  numberToCall() {
    return axios.get(`${this.url}/number_to_call`);
  }
}

export default new StringeeChannel();
