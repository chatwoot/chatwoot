import ApiClient from './ApiClient';

class WebHooks extends ApiClient {
  constructor() {
    super('account/webhooks');
  }
}

export default new WebHooks();
