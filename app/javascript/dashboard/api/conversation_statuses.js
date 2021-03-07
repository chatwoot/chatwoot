import ApiClient from './ApiClient';

class ConversationStatusesAPI extends ApiClient {
  constructor() {
    super('conversation_statuses', { accountScoped: true });
  }
}

export default new ConversationStatusesAPI();
