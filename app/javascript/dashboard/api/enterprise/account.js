/* global axios */
import ApiClient from '../ApiClient';

class EnterpriseAccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true, enterprise: true });
  }

  // V1 endpoints
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

  // V2 Billing endpoints
  get v2BillingUrl() {
    const accountId = this.accountIdFromRoute;
    return `/enterprise/api/v2/accounts/${accountId}/billing`;
  }

  getCreditGrants() {
    return axios.get(`${this.v2BillingUrl}/credit_grants`);
  }

  getPricingPlans() {
    return axios.get(`${this.v2BillingUrl}/pricing_plans`);
  }

  getTopupOptions() {
    return axios.get(`${this.v2BillingUrl}/topup_options`);
  }

  topupCredits(credits) {
    return axios.post(`${this.v2BillingUrl}/topup`, { credits });
  }

  subscribeToPlan(pricingPlanId, quantity) {
    return axios.post(`${this.v2BillingUrl}/subscribe`, {
      pricing_plan_id: pricingPlanId,
      quantity,
    });
  }

  cancelSubscription(reason = null, feedback = null) {
    return axios.post(`${this.v2BillingUrl}/cancel_subscription`, {
      reason,
      feedback,
    });
  }

  changePricingPlan(pricingPlanId, quantity) {
    return axios.post(`${this.v2BillingUrl}/change_pricing_plan`, {
      pricing_plan_id: pricingPlanId,
      quantity,
    });
  }
}

export default new EnterpriseAccountAPI();
