/* global axios */
import ApiClient from './ApiClient';

class AutomationsAPI extends ApiClient {
  constructor() {
    super('automation_rules', { accountScoped: true });
  }

  clone(automationId) {
    return axios.post(`${this.url}/${automationId}/clone`);
  }

  toggle(automationId) {
    return axios.post(`${this.url}/${automationId}/staus_update`);
  }
}

export default new AutomationsAPI();
