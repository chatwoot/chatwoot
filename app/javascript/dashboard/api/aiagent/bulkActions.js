import ApiClient from '../ApiClient';

class AiagentBulkActionsAPI extends ApiClient {
  constructor() {
    super('aiagent/bulk_actions', { accountScoped: true });
  }
}

export default new AiagentBulkActionsAPI();
