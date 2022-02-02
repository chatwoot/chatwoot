import ApiClient from './ApiClient';

class AutomationsAPI extends ApiClient {
  constructor() {
    super('automation_rules', { accountScoped: true });
  }
}

export default new AutomationsAPI();
