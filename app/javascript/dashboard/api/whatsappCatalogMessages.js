/* global axios */
import ApiClient from './ApiClient';

class WhatsappCatalogMessages extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  create(conversationId, payload) {
    return axios.post(`${this.url}/${conversationId}/catalog_message`, payload);
  }
}

export default new WhatsappCatalogMessages();
