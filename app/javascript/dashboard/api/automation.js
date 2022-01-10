import ApiClient from './ApiClient';

class LabelsAPI extends ApiClient {
  constructor() {
    super('automation_rules', { accountScoped: true });
  }
}

export default new LabelsAPI();
