/* global axios */
import ApiClient from '../ApiClient';

class WhatsappUnofficialChannel extends ApiClient {
  constructor() {
    super('channels/whatsapp_unofficial', { accountScoped: true });
  }

  connect({ phone_number }) {
    return axios.post(`${this.url}/connect`, {
      whatsapp_unofficial: { phone_number },
    });
  }

  findByPhone({ phone_number }) {
    return axios.get(`${this.url}/find`, { params: { phone_number } });
  }

  getQr(channelId) {
    return axios.get(`${this.url}/${channelId}/qr`);
  }

  getStatus(channelId) {
    return axios.get(`${this.url}/${channelId}/status`);
  }

  logout(channelId) {
    return axios.post(`${this.url}/${channelId}/logout`);
  }
}

export default new WhatsappUnofficialChannel();
