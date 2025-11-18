/* global axios */

import ApiClient from '../ApiClient';

class EcommerceAPI extends ApiClient {
  constructor() {
    super('integrations/ecommerce', { accountScoped: true });
  }

  getProducts(params = {}) {
    return axios.get(`${this.url}/products`, { params });
  }

  sendProduct(conversationId, productId) {
    return axios.post(`${this.url}/send_product`, {
      conversation_id: conversationId,
      product_id: productId,
    });
  }
}

export default new EcommerceAPI();
