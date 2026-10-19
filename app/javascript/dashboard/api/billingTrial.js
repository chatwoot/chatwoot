/* global axios */
import ApiClient from './ApiClient';

class BillingTrialAPI extends ApiClient {
  constructor() {
    super('billing_trial', { accountScoped: true });
  }

  start() {
    return axios.post(this.url);
  }

  updateSeats(quantity) {
    return axios.patch(this.url, { quantity });
  }
}

export default new BillingTrialAPI();
