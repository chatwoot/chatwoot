/* global axios */
import ApiClient from './ApiClient';

class WhatsappConnectionAPI extends ApiClient {
  constructor() {
    super('whatsapp/connection_check', { accountScoped: true });
  }

  // Último check persistido (provider_config['last_connection_check']).
  getStatus() {
    return axios.get(this.url);
  }

  // Roda o check da instância AGORA.
  runCheck() {
    return axios.post(this.url);
  }
}

export default new WhatsappConnectionAPI();
