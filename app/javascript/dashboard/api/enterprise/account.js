/* global axios */
import ApiClient from '../ApiClient';

class EnterpriseAccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true, enterprise: true });
  }

  checkout() {
    return axios.post(`${this.url}checkout`);
  }

  subscription() {
    return axios.post(`${this.url}subscription`);
  }

  selectBillingCurrency(currency) {
    return axios.post(`${this.url}select_billing_currency`, { currency });
  }

  getLimits() {
    return axios.get(`${this.url}limits`);
  }

  toggleDeletion(action) {
    return axios.post(`${this.url}toggle_deletion`, {
      action_type: action,
    });
  }

  createTopupCheckout(credits) {
    return axios.post(`${this.url}topup_checkout`, { credits });
  }

  // Topup packages for the account's billing currency.
  getTopupOptions() {
    return axios.get(`${this.url}topup_options`);
  }
}

export default new EnterpriseAccountAPI();
