/* global axios */
import ApiClient from './ApiClient';

class ContactAPI extends ApiClient {
  constructor() {
    super('contacts');
  }

  getConversations(contactId) {
    return axios.get(`${this.url}/${contactId}/conversations`);
  }
}

export default new ContactAPI();
