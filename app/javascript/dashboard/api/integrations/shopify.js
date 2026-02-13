/* global axios */

import ApiClient from '../ApiClient';

class ShopifyAPI extends ApiClient {
  constructor() {
    super('integrations/shopify', { accountScoped: true });
  }

  getOrders(contactId) {
    return axios.get(`${this.url}/orders`, {
      params: { contact_id: contactId },
    });
  }

  completeInstall(pendingInstallToken) {
    return axios.post(`${this.url}/complete_install`, {
      pending_install_token: pendingInstallToken,
    });
  }
}

export default new ShopifyAPI();
