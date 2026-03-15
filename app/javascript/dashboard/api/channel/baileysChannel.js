/* global axios */
import ApiClient from '../ApiClient';

class BaileysChannel extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  requestQrCode(inboxId) {
    return axios.post(`${this.url}/${inboxId}/baileys_qr_code`);
  }

  getStatus(inboxId) {
    return axios.get(`${this.url}/${inboxId}/baileys_status`);
  }

  disconnect(inboxId) {
    return axios.post(`${this.url}/${inboxId}/baileys_disconnect`);
  }
}

export default new BaileysChannel();
