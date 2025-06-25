/* global axios */
import ApiClient from './ApiClient';

class OrdersAPI extends ApiClient {
  constructor() {
    super('reports', { accountScoped: true, apiVersion: 'v2' });
  }

  calculateRefund({}) {}
}

export default new OrdersAPI();
