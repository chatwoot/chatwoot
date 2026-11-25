import ApiClient from '../ApiClient';

class MessageReports extends ApiClient {
  constructor() {
    super('captain/message_reports', { accountScoped: true });
  }
}

export default new MessageReports();
