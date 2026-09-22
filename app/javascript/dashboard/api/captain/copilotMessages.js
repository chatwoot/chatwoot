/* global axios */
import ApiClient from '../ApiClient';

class CopilotMessages extends ApiClient {
  constructor() {
    super('captain/copilot_threads', { accountScoped: true });
  }

  get(threadId, params = {}) {
    return axios.get(`${this.url}/${threadId}/copilot_messages`, { params });
  }

  create({ threadId, ...rest }) {
    return axios.post(`${this.url}/${threadId}/copilot_messages`, rest);
  }
}

export default new CopilotMessages();
