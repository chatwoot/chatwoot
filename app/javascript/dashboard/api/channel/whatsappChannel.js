/* global axios */
import ApiClient from '../ApiClient';

class WhatsappChannel extends ApiClient {
  constructor() {
    super('whatsapp', { accountScoped: true });
  }

  createEmbeddedSignup(params) {
    return axios.post(`${this.baseUrl()}/whatsapp/authorization`, params);
  }
}

export default new WhatsappChannel();
