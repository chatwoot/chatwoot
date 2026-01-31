/* global axios */
import ApiClient from '../ApiClient';

class CaptainAssistantMcpServersAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  getUrl(assistantId) {
    return `${this.baseUrl()}/captain/assistants/${assistantId}/mcp_servers`;
  }

  get(assistantId) {
    return axios.get(this.getUrl(assistantId));
  }

  create(assistantId, data) {
    return axios.post(this.getUrl(assistantId), data);
  }

  update(assistantId, id, data) {
    return axios.patch(`${this.getUrl(assistantId)}/${id}`, data);
  }

  delete(assistantId, id) {
    return axios.delete(`${this.getUrl(assistantId)}/${id}`);
  }
}

export default new CaptainAssistantMcpServersAPI();
