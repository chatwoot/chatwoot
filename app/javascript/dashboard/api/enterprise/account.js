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

  getBillingDetails() {
    return axios.get(`${this.url}billing_details`);
  }

  confirmBillingDetails({ businessName, businessAddress, billingEmail }) {
    return axios.post(`${this.url}confirm_billing_details`, {
      business_name: businessName,
      business_address: businessAddress,
      billing_email: billingEmail,
    });
  }
}

export default new EnterpriseAccountAPI();
