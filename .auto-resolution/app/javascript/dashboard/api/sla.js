import ApiClient from './ApiClient';

class SlaAPI extends ApiClient {
  constructor() {
    super('sla_policies', { accountScoped: true });
  }
}

export default new SlaAPI();
