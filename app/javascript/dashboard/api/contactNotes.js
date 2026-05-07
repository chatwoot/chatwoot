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

  create(contactId, content) {
    this.contactId = contactId;
    return super.create({ content });
  }

  update(contactId, id, { content, metadata }) {
    this.contactId = contactId;
    return super.update(id, { note: { content, metadata } });
  }

  delete(contactId, id) {
    this.contactId = contactId;
    return super.delete(id);
  }
}

export default new ContactNotes();
