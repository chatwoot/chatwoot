/* global axios */

import ApiClient from '../ApiClient';

class TiendanubeAPI extends ApiClient {
  constructor() {
    super('integrations/tiendanube', { accountScoped: true });
  }

  connectTiendanube(storeId) {
    return axios.post(`${this.url}/auth`, {
      store_id: storeId,
    });
  }

  getOrders(contactId) {
    return axios.get(`${this.url}/orders`, {
      params: { contact_id: contactId },
    });
  }
}

export default new TiendanubeAPI();
