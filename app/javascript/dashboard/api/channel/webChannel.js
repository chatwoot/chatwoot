import ApiClient from '../ApiClient';

class WebChannel extends ApiClient {
  constructor() {
    super('widget/inboxes');
  }
}

export default new WebChannel();
