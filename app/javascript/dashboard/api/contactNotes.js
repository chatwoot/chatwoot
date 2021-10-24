import ApiClient from './ApiClient';

class ContactNotes extends ApiClient {
  constructor() {
    super('notes', { accountScoped: true });
    this.contactId = null;
  }

  get url() {
    return `${this.baseUrl()}/contacts/${this.contactId}/notes`;
  }

  get(contactId) {
    this.contactId = contactId;
    return super.get();
  }
}

export default new ContactNotes();
