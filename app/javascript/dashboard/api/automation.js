/* global axios */
import ApiClient from '../ApiClient';

class AutomationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  saveAutomation({ automation }) {
    return axios.post(`${this.url}/automation`, {
      automation,
    });
  }
}

export default new AutomationApi();
