import ApiClient from '../ApiClient';

class CaptainBulkActionsAPI extends ApiClient {
  constructor() {
    super('captain/bulk_actions', { accountScoped: true });
  }
}

export default new CaptainBulkActionsAPI();
