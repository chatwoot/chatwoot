import ApiClient from './ApiClient';

class FlowsAPI extends ApiClient {
  constructor() {
    super('flows', { accountScoped: true });
  }
}

export default new FlowsAPI();
