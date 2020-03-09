import ApiClient from './ApiClient';

class Inboxes extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }
}

export default new Inboxes();
