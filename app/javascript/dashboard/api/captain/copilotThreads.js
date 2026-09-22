/* global axios */
import ApiClient from '../ApiClient';

class CopilotThreads extends ApiClient {
  constructor() {
    super('captain/copilot_threads', { accountScoped: true });
  }

  get(params = {}) {
    return axios.get(this.url, { params });
  }
}

export default new CopilotThreads();
