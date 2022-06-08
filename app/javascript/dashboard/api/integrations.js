import ApiClient from './ApiClient';

class IntegrationsAPI extends ApiClient {
  constructor() {
    super('integrations/apps', { accountScoped: true });
  }

  connectSlack(code) {
    return this.axios.post(`${this.baseUrl()}/integrations/slack`, {
      code: code,
    });
  }

  delete(integrationId) {
    return this.axios.delete(`${this.baseUrl()}/integrations/${integrationId}`);
  }

  createHook(hookData) {
    return this.axios.post(`${this.baseUrl()}/integrations/hooks`, hookData);
  }

  deleteHook(hookId) {
    return this.axios.delete(`${this.baseUrl()}/integrations/hooks/${hookId}`);
  }
}

export default new IntegrationsAPI();
