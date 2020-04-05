/* global axios */
import ApiClient from './ApiClient';

class AccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  getAccount() {
    return axios.get(`${this.url}`);
  }
}

export default new AccountAPI();
