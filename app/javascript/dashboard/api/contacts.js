/* global axios */
import ApiClient from './ApiClient';

class ContactAPI extends ApiClient {
  constructor() {
    super('contacts', { accountScoped: true });
  }

  get(page, sortAttr = 'name') {
    return axios.get(`${this.url}?page=${page}&sort=${sortAttr}`);
  }

  getConversations(contactId) {
    return axios.get(`${this.url}/${contactId}/conversations`);
  }

  getContactableInboxes(contactId) {
    return axios.get(`${this.url}/${contactId}/contactable_inboxes`);
  }

  getContactLabels(contactId) {
    return axios.get(`${this.url}/${contactId}/labels`);
  }

  updateContactLabels(contactId, labels) {
    return axios.post(`${this.url}/${contactId}/labels`, { labels });
  }

  search(search = '', page = 1, sortAttr = 'name') {
    return axios.get(
      `${this.url}/search?q=${search}&page=${page}&sort=${sortAttr}`
    );
  }
}

export default new ContactAPI();
