import ApiClient from '../ApiClient';

class WebChannel extends ApiClient {
  constructor() {
    super('widget/inboxes', { accountScoped: true });
  }
}

export default new WebChannel();
