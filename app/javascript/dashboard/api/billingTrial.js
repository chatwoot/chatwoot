/* global axios */
import ApiClient from './ApiClient';

class BillingTrialAPI extends ApiClient {
  constructor() {
    super('billing_trial', { accountScoped: true });
  }

  start() {
    return axios.post(this.url);
  }
}

export default new BillingTrialAPI();
