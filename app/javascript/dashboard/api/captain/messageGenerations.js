import ApiClient from '../ApiClient';

class MessageGenerations extends ApiClient {
  constructor() {
    super('captain/message_generations', { accountScoped: true });
  }
}

export default new MessageGenerations();
