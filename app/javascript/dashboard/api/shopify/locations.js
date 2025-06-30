/* global axios */
import ApiClient from '../ApiClient';

class ShopifyLocationsAPI extends ApiClient {
  constructor() {
    super('shopify/locations', { accountScoped: true, apiVersion: 'v2' });
  }
}

export default new ShopifyLocationsAPI();
