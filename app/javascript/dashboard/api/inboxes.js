import ApiClient from './ApiClient';

class Inboxes extends ApiClient {
  constructor() {
    super('inboxes');
  }
}

export default new Inboxes();
