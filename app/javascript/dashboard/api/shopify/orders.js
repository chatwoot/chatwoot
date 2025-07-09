/* global axios */
import ApiClient from '../ApiClient';

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

  refundOrder({
    orderId,
    transactions,
    note,
    notify,
    currency,
    shipping,
    refundLineItems: refund_line_items,
  }) {
    return axios.post(`${this.url}/${orderId}/refund_order`, {
      transactions,
      note,
      notify,
      currency,
      shipping,
      refund_line_items,
    });
  }

  // permitted = params.permit()

  calculateRefund({ orderId, currency, refundLineItems: refund_line_items }) {
    return axios.post(`${this.url}/${orderId}/calculate_refund`, {
      currency,
      refund_line_items,
    });
  }

  orderDetails({ orderId }) {
    return axios.get(`${this.url}/${orderId}/order_details`);
  }

  fulfillmentOrders({ orderId }) {
    return axios.get(`${this.url}/${orderId}/fulfillment_orders`);
  }

  returnCalculate({ orderId, returnLineItems, returnShippingFee }) {
    return axios.post(`${this.url}/${orderId}/return_calculate`, {
      returnLineItems,
      returnShippingFee,
    });
  }

  returnCreate({ orderId, returnLineItems, returnShippingFee }) {
    return axios.post(`${this.url}/${orderId}/return_create`, {
      returnLineItems,
      returnShippingFee,
    });
  }

  fulfillmentCreate({ orderId, ...rest }) {
    return axios.post(`${this.url}/${orderId}/fulfillment_create`, rest);
  }
}

export default new OrdersAPI();
