import ApiClient from './ApiClient';

class SenderListEntriesAPI extends ApiClient {
  constructor() {
    super('sender_list_entries', { accountScoped: true });
  }
}

export default new SenderListEntriesAPI();
