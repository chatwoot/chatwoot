import ApiClient from './ApiClient';

class DashassistShopifyAPI extends ApiClient {
  constructor() {
    super('dashassist_shopify/stores', { accountScoped: true });
  }

  get accountIdFromRoute() {
    const isInsideAccountScopedURLs =
      window.location.pathname.includes('/app/accounts');

    if (isInsideAccountScopedURLs) {
      return window.location.pathname.split('/')[3];
    }

    return null;
  }

  getStoreByInboxId(inboxId) {
    console.log('DashassistShopifyAPI: getByInboxId called with inboxId:', inboxId);
    const url = `${this.url}/inbox/${inboxId}`;
    console.log('DashassistShopifyAPI: Requesting URL:', url);
    return this.get(url);
  }

  toggleChatBot(storeId, enabled) {
    return this.update(storeId, { enabled });
  }
}

export default new DashassistShopifyAPI(); 