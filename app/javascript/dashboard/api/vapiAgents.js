/* global axios */
import ApiClient from './ApiClient';

class VapiAgentsAPI extends ApiClient {
  constructor() {
    super('vapi_agents', { accountScoped: true });
  }

  fetchFromVapi(vapiAgentId, inboxId) {
    return axios.get(
      `${this.url}/fetch_from_vapi/${vapiAgentId}?inbox_id=${inboxId}`
    );
  }

  importFromVapi(vapiAgentId, inboxId) {
    return axios.get(
      `${this.url}/import_from_vapi/${vapiAgentId}?inbox_id=${inboxId}`
    );
  }
}

export default new VapiAgentsAPI();
