import ApiClient from './ApiClient';

class WebHooks extends ApiClient {
  constructor() {
    super('webhooks', { accountScoped: true });
  }
}

export default new WebHooks();
