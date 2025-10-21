/* global axios */

import ApiClient from './ApiClient';

class BillingAPI extends ApiClient {
  constructor() {
    super('subscriptions', { accountScoped: true });
  }

  myActiveSubscription() {
    return axios.get(`${this.url}/active`);
  }
  
  latestSubscription() {
    return axios.get(`${this.url}/latest`);
  }

  transactionHistories() {
    return axios.get(`${this.url}/histories`);
  }

  pricingPlans() {
    return axios.get(`${this.url}/plans`);
  }

  customPlans() {
    return axios.get(`${this.url}/custom_plans`);
  }

  createSubscription({
    id,
    name,
    status,
    plan_id,
    user_id,
    payment_method,
    billing_cycle,
    qty,
    voucher_code = null,
  }) {
    const requestData = {
      id,
      name,
      status,
      plan_id,
      user_id,
      payment_method,
      billing_cycle,
      qty,
      voucher_code,
    };

    return axios.post(this.url, requestData);
  }

  createTopup({ subscription_id, topup_type, amount, payment_method }) {
    const requestData = {
      topup: {
        topup_type,
        amount,
      },
      subscription_id,
      payment_method,
    };

    return axios.post(`${this.url}/${subscription_id}/topup`, requestData);
  }
}

export default new BillingAPI();
