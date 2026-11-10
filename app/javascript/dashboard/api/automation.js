/* global axios */
import ApiClient from './ApiClient';

class AutomationsAPI extends ApiClient {
  constructor() {
    super('automation_rules', { accountScoped: true });
  }

  clone(automationId) {
    return axios.post(`${this.url}/${automationId}/clone`);
  }

  linkedToMonitor(monitorId, signal) {
    return axios.get(this.url, { params: { monitor_id: monitorId }, signal });
  }
}

export default new AutomationsAPI();
