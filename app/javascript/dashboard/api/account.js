/* global axios */
import ApiClient from './ApiClient';

class AccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  createAccount(data) {
    return axios.post(`${this.apiVersion}/accounts`, data);
  }

  getPermissionsByUser(userId) {
    this.setApiVersion('v2');
    const url = `${this.apiVersion}/accounts/${this.accountIdFromRoute}/permissions/${userId}`;
    return axios.get(url);
  }

  updatePermissionsByUser(userId, data) {
    this.setApiVersion('v2');
    const url = `${this.apiVersion}/accounts/${this.accountIdFromRoute}/permissions/${userId}`;
    return axios.patch(url, data);
  }
}

export default new AccountAPI();
