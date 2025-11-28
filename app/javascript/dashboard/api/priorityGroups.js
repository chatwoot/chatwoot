import ApiClient from './ApiClient';

class PriorityGroupsApi extends ApiClient {
  constructor() {
    super('priority_groups', { accountScoped: true });
  }

  index() {
    return this.get();
  }
}

export default new PriorityGroupsApi();
