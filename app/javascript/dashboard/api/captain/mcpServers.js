/* global axios */
import ApiClient from '../ApiClient';

class CaptainMcpServers extends ApiClient {
  constructor() {
    super('captain/mcp_servers', { accountScoped: true });
  }

  get({ assistantId, signal } = {}) {
    return axios.get(this.url, {
      params: { assistant_id: assistantId },
      signal,
    });
  }

  discover({ assistantId, url, token, authHeader }) {
    return axios.post(`${this.url}/discover`, {
      assistant_id: assistantId,
      url,
      token,
      auth_header: authHeader,
    });
  }

  create({ assistantId, ...data }) {
    return axios.post(this.url, {
      assistant_id: assistantId,
      mcp_server: data,
    });
  }

  update(id, { assistantId, ...data }) {
    return axios.patch(`${this.url}/${id}`, {
      assistant_id: assistantId,
      mcp_server: data,
    });
  }

  delete({ id, assistantId }) {
    return axios.delete(`${this.url}/${id}`, {
      params: { assistant_id: assistantId },
    });
  }

  liveTools({ id, assistantId, signal }) {
    return axios.get(`${this.url}/${id}/live_tools`, {
      params: { assistant_id: assistantId },
      signal,
    });
  }

  authorizationUrl({ id, assistantId }) {
    return axios.get(`${this.url}/${id}/authorization_url`, {
      params: { assistant_id: assistantId },
    });
  }
}

export default new CaptainMcpServers();
