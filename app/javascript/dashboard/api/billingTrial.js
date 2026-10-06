/* global axios */
import ApiClient from './ApiClient';

class BillingTrialAPI extends ApiClient {
  constructor() {
    super('billing_trial', { accountScoped: true });
  }

  start(planName, seats) {
    return axios.post(this.url, { plan_name: planName, seats });
  }

  complete(sessionId) {
    return axios.post(`${this.url}/complete`, { session_id: sessionId });
  }
}

export default new BillingTrialAPI();
