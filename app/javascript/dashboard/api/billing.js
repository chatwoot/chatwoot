/* global axios */

import ApiClient from './ApiClient';

class BillingAPI extends ApiClient{
  constructor() {
    super('subscriptions', { accountScoped: true });
  }

  myActiveSubscription() {
    return axios.get(this.url);
  }
};

export default new BillingAPI();