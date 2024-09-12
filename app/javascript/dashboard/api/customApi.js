import ApiClient from './ApiClient';

class CustomApiAPI extends ApiClient {
  constructor() {
    super('custom_apis', { accountScoped: true });
  }
}

export default new CustomApiAPI();
