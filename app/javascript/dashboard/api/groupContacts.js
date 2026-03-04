/* global axios */
import ApiClient from './ApiClient';

class GroupContactsAPI extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getGroupContacts(conversationId, { page = 1 } = {}) {
    return axios.get(
      `${this.url}/${conversationId}/group_contacts?page=${page}`
    );
  }
}

export default new GroupContactsAPI();
