/* global axios */

import ApiClient from './ApiClient';

class IntegrationsAPI extends ApiClient {
  constructor() {
    super('integrations/apps', { accountScoped: true });
  }

  connectSlack(code) {
    return axios.post(`${this.baseUrl()}/integrations/slack`, {
      code: code,
    });
  }

  delete(integrationId) {
    return axios.delete(`${this.baseUrl()}/integrations/${integrationId}`);
  }
}

export default new IntegrationsAPI();
