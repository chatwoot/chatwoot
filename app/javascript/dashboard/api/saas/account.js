/* global axios */
import ApiClient from '../ApiClient';

class SaasAccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true, saas: true });
  }

  checkout(planId) {
    return axios.post(`${this.url}checkout`, { plan_id: planId });
  }

  subscription() {
    return axios.post(`${this.url}subscription`);
  }

  getLimits() {
    return axios.get(`${this.url}limits`);
  }

  getPlans() {
    return axios.get(`${this.url}plans`);
  }
}

export default new SaasAccountAPI();
