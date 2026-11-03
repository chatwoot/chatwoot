/* global axios */
import ApiClient from '../ApiClient';

class CopilotRuns extends ApiClient {
  constructor() {
    super('captain/copilot_runs', { accountScoped: true });
  }

  approve(runId) {
    return axios.post(`${this.url}/${runId}/approve`);
  }

  reject(runId) {
    return axios.post(`${this.url}/${runId}/reject`);
  }
}

export default new CopilotRuns();
