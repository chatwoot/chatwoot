/* global axios */
import ApiClient from './ApiClient';

class BillingAPI extends ApiClient {
  constructor() {
    super('subscription', { accountScoped: true });
  }

  getSubscription() {
    return axios.get(this.url);
  }

  createCheckout(planKey) {
    return axios.post(`${this.url}/checkout`, { plan_key: planKey });
  }

  getPortalUrl() {
    return axios.post(`${this.url}/portal`);
  }

  swapPlan(planKey) {
    return axios.post(`${this.url}/swap`, { plan_key: planKey });
  }

  cancel() {
    return axios.post(`${this.url}/cancel`);
  }

  resume() {
    return axios.post(`${this.url}/resume`);
  }
}

export default new BillingAPI();
