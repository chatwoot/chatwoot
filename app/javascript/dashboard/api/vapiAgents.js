import ApiClient from './ApiClient';

class VapiAgentsAPI extends ApiClient {
  constructor() {
    super('vapi_agents', { accountScoped: true });
  }

  fetchFromVapi(vapiAgentId, inboxId) {
    return this.get(`fetch_from_vapi/${vapiAgentId}?inbox_id=${inboxId}`);
  }

  importFromVapi(vapiAgentId, inboxId) {
    const url = `import_from_vapi/${vapiAgentId}?inbox_id=${inboxId}`;
    return this.get(url);
  }
}

export default new VapiAgentsAPI();
