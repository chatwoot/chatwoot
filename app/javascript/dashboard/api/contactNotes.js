import ApiClient from './ApiClient';

class ContactNotes extends ApiClient {
  constructor() {
    super('contact_notes', { accountScoped: true });
  }
}

export default new ContactNotes();
