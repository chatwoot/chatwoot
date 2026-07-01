import ApiClient from './ApiClient';

class WorkflowsAPI extends ApiClient {
  constructor() {
    super('workflows');
  }
}

export default new WorkflowsAPI();
