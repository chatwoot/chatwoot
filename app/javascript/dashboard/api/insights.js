import ApiClient from './ApiClient';

class InsightsAPI extends ApiClient {
  constructor() {
    super('insights', { accountScoped: true });
  }
}

export default new InsightsAPI();
