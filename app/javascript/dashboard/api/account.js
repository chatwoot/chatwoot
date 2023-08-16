/* global axios */
import ApiClient from './ApiClient';

class AccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  createAccount(data) {
    return axios.post(`${this.apiVersion}/accounts`, data);
  }

  getBillingSubscription() {
    return axios.get(`${this.url}billing_subscription`);
  }

  changePlan(data) {
    return axios.post(`${this.url}change_plan`, data);
  }
}

export default new AccountAPI();
