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

  switchCurrency(currency) {
    return axios.post(`${this.url}/switch_currency`, { currency });
  }
}

export default new BillingTrialAPI();
