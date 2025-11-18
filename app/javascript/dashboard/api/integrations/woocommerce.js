/* global axios */

import ApiClient from '../ApiClient';

class WoocommerceAPI extends ApiClient {
  constructor() {
    super('integrations/woocommerce', { accountScoped: true });
  }

  testConnection(settings) {
    return axios.post(`${this.url}/test_connection`, { settings });
  }

  getProducts(params = {}) {
    return axios.get(`${this.url}/products`, { params });
  }
}

export default new WoocommerceAPI();
