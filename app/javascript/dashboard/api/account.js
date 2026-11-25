/* global axios */
import ApiClient from './ApiClient';

class AccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  get(accountId) {
    return accountId
      ? axios.get(`${this.apiVersion}/accounts/${accountId}`)
      : super.get();
  }

  createAccount(data) {
    return axios.post(`${this.apiVersion}/accounts`, data);
  }

  updateBrandLogoEmail(file) {
    const formData = new FormData();
    formData.append('brand_logo_email', file);
    return axios.patch(
      `${this.apiVersion}/accounts/${this.accountIdFromRoute}`,
      formData
    );
  }

  deleteBrandLogoEmail() {
    return axios.delete(
      `${this.apiVersion}/accounts/${this.accountIdFromRoute}/brand_logo_email`
    );
  }

  async getCacheKeys() {
    const response = await axios.get(
      `/api/v1/accounts/${this.accountIdFromRoute}/cache_keys`
    );
    return response.data.cache_keys;
  }
}

export default new AccountAPI();
