import ApiClient from './ApiClient';

class WhatsAppUnofficialChannels extends ApiClient {
  constructor() {
    super('channels/whatsapp_unofficial_channels', { accountScoped: true });
  }

  create({ phone_number, inbox_name }) {
    return axios.post(this.url, {
      phone_number,
      inbox_name,
    });
  }

  generateQR(inboxId) {
    return axios.get(`${this.baseUrl()}/inboxes/${inboxId}/whatsapp/qr`);
  }

  getConnectionStatus(inboxId, realTime = false) {
    const params = realTime ? { real_time: 'true' } : {};
    return axios.get(`${this.baseUrl()}/inboxes/${inboxId}/whatsapp/status`, { params });
  }

  restartSession(inboxId) {
    return axios.post(`${this.baseUrl()}/inboxes/${inboxId}/whatsapp/restart`);
  }
}

export default new WhatsAppUnofficialChannels();
