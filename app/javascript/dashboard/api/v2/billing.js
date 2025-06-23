/* global axios */
import ApiClient from '../ApiClient';

class BillingAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true, apiVersion: 'v2' });
  }

  // GET /api/v2/accounts/:account_id/subscription
  getSubscription() {
    return axios.get(`${this.url}subscription`);
  }

  // POST /api/v2/accounts/:account_id/subscription
  createSubscription(planName = 'free') {
    return axios.post(`${this.url}subscription`, {
      subscription: { plan_name: planName },
    });
  }

  // GET /api/v2/accounts/:account_id/subscription/portal
  getBillingPortal(returnUrl = null) {
    const params = returnUrl ? { return_url: returnUrl } : {};
    return axios.get(`${this.url}subscription/portal`, {
      params,
    });
  }

  // GET /api/v2/accounts/:account_id/subscription/limits
  getLimits() {
    return axios.get(`${this.url}subscription/limits`);
  }
}

export default new BillingAPI();
