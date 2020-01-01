import ApiClient from './ApiClient';

class ContactAPI extends ApiClient {
  constructor() {
    super('contacts');
  }
}

export default new ContactAPI();
