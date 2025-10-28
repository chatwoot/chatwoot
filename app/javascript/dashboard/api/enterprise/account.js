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

  // V2 Billing APIs
  creditsBalance() {
    return axios.get(`${this.url}credits_balance`);
  }

  creditGrants() {
    return axios.get(`${this.url}credit_grants`);
  }

  v2PricingPlans() {
    return axios.get(`${this.url}v2_pricing_plans`);
  }

  v2TopupOptions() {
    return axios.get(`${this.url}v2_topup_options`);
  }

  v2Topup(data) {
    return axios.post(`${this.url}v2_topup`, data);
  }

  v2Subscribe(data) {
    return axios.post(`${this.url}v2_subscribe`, data);
  }

  cancelSubscription(data = {}) {
    return axios.post(`${this.url}cancel_subscription`, data);
  }

  updateSubscriptionQuantity(quantity) {
    return axios.post(`${this.url}update_subscription_quantity`, {
      quantity,
    });
  }

  changePricingPlan(data) {
    return axios.post(`${this.url}change_pricing_plan`, data);
  }
}

export default new EnterpriseAccountAPI();
