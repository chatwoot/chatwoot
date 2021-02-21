import ApiClient from './ApiClient';

class ChatStatusItemsAPI extends ApiClient {
  constructor() {
    super('chat_status_items', { accountScoped: true });
  }
}

export default new ChatStatusItemsAPI();
