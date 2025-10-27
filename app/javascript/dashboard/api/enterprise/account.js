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

  getCreditBalance() {
    return axios.get(`${this.url}credits_balance`);
  }

  getV2PricingPlans() {
    return axios.get(`${this.url}v2_pricing_plans`);
  }

  getV2TopupOptions() {
    return axios.get(`${this.url}v2_topup_options`);
  }

  purchaseTopup(credits) {
    return axios.post(`${this.url}v2_topup`, { credits });
  }

  subscribeToV2Plan(pricing_plan_id, quantity = 1) {
    return axios.post(`${this.url}v2_subscribe`, { pricing_plan_id, quantity });
  }

  cancelSubscription(options = {}) {
    const { feedback = null, comment = null } = options;

    return axios.post(`${this.url}cancel_subscription`, {
      feedback,
      comment,
    });
  }
}

export default new EnterpriseAccountAPI();
