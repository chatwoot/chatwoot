/* global axios */

import ApiClient from './ApiClient';

class BillingAPI extends ApiClient{
  constructor() {
    super('subscriptions', { accountScoped: true });
  }

  myActiveSubscription() {
    return axios.get(`${this.url}/active`);
  }

  subscriptionHistories() {
    return axios.get(this.url);
  }

  createSubscription({
    id,
    name,
    status,
    plan_id,
    user_id,
    payment_method
  }) {
    const requestData = {
      id,
      name,
      status,
      plan_id,
      user_id,
      payment_method
    };

    return axios.post(this.url, requestData);
  }
};

export default new BillingAPI();