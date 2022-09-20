import ApiClient from './ApiClient';

class MacrosAPI extends ApiClient {
  constructor() {
    super('macros', { accountScoped: true });
  }
}

export default new MacrosAPI();
