/* global axios */
import ApiClient from './ApiClient';

class AutomationsAPI extends ApiClient {
  constructor() {
    super('automation_rules', { accountScoped: true });
  }

  clone(automationId) {
    return axios.post(`${this.url}/${automationId}/clone`);
  }

  toggle(automationId, params) {
    return axios.patch(`${this.url}/${automationId}`, params);
  }
}

export default new AutomationsAPI();
