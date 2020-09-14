/* global axios */
import ApiClient from './ApiClient';

class ContactAPI extends ApiClient {
  constructor() {
    super('contacts', { accountScoped: true });
  }

  getConversations(contactId) {
    return axios.get(`${this.url}/${contactId}/conversations`);
  }

  search(search = '') {
    return axios.get(`${this.url}/search?q=${search}`);
  }
}

export default new ContactAPI();
