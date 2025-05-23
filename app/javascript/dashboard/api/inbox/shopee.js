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

  getOrders(params) {
    return axios.get(`${this.url}/${params.conversationID}/shopee/orders`, {
      params: {
        order_status: params.orderStatus,
      },
    });
  }

  searchProducts(conversationID, keyword) {
    return axios.get(`${this.url}/${conversationID}/shopee/products`, {
      params: { keyword },
    });
  }

  sendOrder(conversationID, orderNumber) {
    return axios.post(`${this.url}/${conversationID}/shopee/send_order`, {
      order_number: orderNumber,
    });
  }

  sendProduct(conversationID, productCodes) {
    return axios.post(`${this.url}/${conversationID}/shopee/send_product`, {
      product_codes: productCodes,
    });
  }

  sendVoucher(conversationID, voucherId, voucherCode) {
    return axios.post(`${this.url}/${conversationID}/shopee/send_voucher`, {
      voucher_id: voucherId,
      voucher_code: voucherCode,
    });
  }
}

export default new ShopeeAPI();
