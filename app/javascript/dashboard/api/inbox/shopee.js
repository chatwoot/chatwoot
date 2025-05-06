/* eslint no-console: 0 */
/* global axios */
import ApiClient from '../ApiClient';

class ShopeeAPI extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getVouchers(params) {
    return axios.get(`${this.url}/${params.conversationID}/shopee/vouchers`);
  }

  getOrders(conversationID) {
    return axios.get(`${this.url}/${conversationID}/shopee/orders`);
  }

  searchProducts(conversationID, keyword) {
    return axios.get(`${this.url}/${conversationID}/shopee/products`, {
      params: { keyword },
    });
  }

  sendOrder(conversationID, orderId) {
    return axios.post(`${this.url}/${conversationID}/shopee/send_order`, {
      order_id: orderId,
    });
  }

  sendProduct(conversationID, productIds) {
    return axios.post(`${this.url}/${conversationID}/shopee/send_product`, {
      product_ids: productIds,
    });
  }

  sendVoucher(conversationID, voucherId) {
    return axios.post(`${this.url}/${conversationID}/shopee/send_voucher`, {
      voucher_id: voucherId,
    });
  }
}

export default new ShopeeAPI();
