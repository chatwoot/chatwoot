/* global axios */
import ApiClient from '../ApiClient';

class CaptainAgentSessions extends ApiClient {
  constructor() {
    super('captain/agent_sessions', { accountScoped: true });
  }

  index({ page = 1 } = {}) {
    return axios.get(this.url, { params: { page } });
  }
}

export default new CaptainAgentSessions();
