import ApiClient from './ApiClient';

class ContactsBulkActionsAPI extends ApiClient {
  constructor() {
    super('contacts/bulk_actions', { accountScoped: true });
  }
}

export default new ContactsBulkActionsAPI();
