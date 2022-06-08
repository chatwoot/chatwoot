import ApiClient from './ApiClient';

class AccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  createAccount(data) {
    return this.axios.post(`${this.apiVersion}/accounts`, data);
  }
}

export default new AccountAPI();
