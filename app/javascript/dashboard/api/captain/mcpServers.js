/* global axios */
import ApiClient from '../ApiClient';

class CaptainMcpServersAPI extends ApiClient {
  constructor() {
    super('captain/mcp_servers', { accountScoped: true });
  }

  connect(id) {
    return axios.post(`${this.url}/${id}/connect`);
  }

  disconnect(id) {
    return axios.post(`${this.url}/${id}/disconnect`);
  }

  refresh(id) {
    return axios.post(`${this.url}/${id}/refresh`);
  }
}

export default new CaptainMcpServersAPI();
