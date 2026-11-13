/* global axios */

import ApiClient from '../ApiClient';

class ShopifyAPI extends ApiClient {
  constructor() {
    super('integrations/shopify', { accountScoped: true });
  }

  getCustomApp() {
    return axios.get(`${this.url}_custom_app`);
  }

  saveCustomApp(data, exists) {
    return axios[exists ? 'patch' : 'post'](`${this.url}_custom_app`, data);
  }

  deleteCustomApp() {
    return axios.delete(`${this.url}_custom_app`);
  }

  connect(shopDomain) {
    return axios.post(`${this.url}/auth`, { shop_domain: shopDomain });
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
