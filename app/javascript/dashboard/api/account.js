/* global axios */
import ApiClient from './ApiClient';

class AccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  createAccount(data) {
    return axios.post(`${this.apiVersion}/accounts`, data);
  }

  getLTD(data) {
    return axios.post(`${this.url}get_ltd`, data);
  }

  getLtdDetails() {
    return axios.get(`${this.url}get_ltd_details`);
  }

  stripe_checkout() {
    return axios.post(`${this.url}stripe_checkout`);
  }

  stripe_subscription() {
    return axios.post(`${this.url}stripe_subscription`);
  }

  async getCacheKeys() {
    const response = await axios.get(
      `/api/v1/accounts/${this.accountIdFromRoute}/cache_keys`
    );
    return response.data.cache_keys;
  }
}

export default new AccountAPI();
