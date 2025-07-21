/* global axios */
import ApiClient from '../ApiClient';

class WhatsappChannel extends ApiClient {
  constructor() {
    super('whatsapp', { accountScoped: true });
  }

  createEmbeddedSignup(params) {
    return axios.post(`${this.baseUrl()}/whatsapp/authorization`, params);
  }

  reauthorizeWhatsApp({ inboxId, ...params }) {
    return axios.put(
      `${this.baseUrl()}/whatsapp/reauthorization/${inboxId}`,
      params
    );
  }

  // Alias for backward compatibility - both upgrade and reauth use the same endpoint
  upgradeToEmbeddedSignup({ inboxId, ...params }) {
    return this.reauthorizeWhatsApp({ inboxId, ...params });
  }
}

export default new WhatsappChannel();
