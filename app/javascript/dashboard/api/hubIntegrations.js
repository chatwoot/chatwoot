/* global axios */
import ApiClient from './ApiClient';

class HubIntegrationsAPI extends ApiClient {
  constructor() {
    super('integrations', { accountScoped: true });
  }

  getAvailableActions() {
    return axios.get(this.url);
  }
}

export default new HubIntegrationsAPI();
