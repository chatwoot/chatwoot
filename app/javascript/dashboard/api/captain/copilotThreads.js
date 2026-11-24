/* global axios */
import ApiClient from '../ApiClient';

class CopilotThreads extends ApiClient {
  constructor() {
    super('captain/copilot_threads', { accountScoped: true });
  }

  get({ page = 1 } = {}) {
    return axios.get(this.url, { params: { page } });
  }

  stop(threadId) {
    return axios.post(`${this.url}/${threadId}/stop`);
  }
}

export default new CopilotThreads();
