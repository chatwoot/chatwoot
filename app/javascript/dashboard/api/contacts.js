/* global axios */
import ApiClient from './ApiClient';

class ContactAPI extends ApiClient {
  constructor() {
    super('contacts', { accountScoped: true });
  }

  get(page) {
    return axios.get(`${this.url}?page=${page}`);
  }

  getConversations(contactId) {
    return axios.get(`${this.url}/${contactId}/conversations`);
  }

  getContactableInboxes(contactId) {
    return axios.get(`${this.url}/${contactId}/contactable_inboxes`);
  }

  search(search = '', page = 1) {
    return axios.get(`${this.url}/search?q=${search}&page=${page}`);
  }
}

export default new ContactAPI();
