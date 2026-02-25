import ApiClient from '../ApiClient';

class WebChannel extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }
}

export default new WebChannel();
