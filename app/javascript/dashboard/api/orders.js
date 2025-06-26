/* global axios */
import ApiClient from './ApiClient';

class OrdersAPI extends ApiClient {
  constructor() {
    super('shopify/orders', { accountScoped: true, apiVersion: 'v2' });
  }

  cancelOrder({
    orderId,
    reason,
    refund,
    restock,
    notifyCustomer: notify_customer,
  }) {
    return axios.post(`${this.url}/${orderId}/cancel_order`, {
      reason,
      refund,
      restock,
      notify_customer,
    });
  }
}

export default new OrdersAPI();
