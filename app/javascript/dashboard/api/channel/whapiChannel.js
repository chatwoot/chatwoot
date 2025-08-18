/* global axios */
import ApiClient from '../ApiClient';

class WhapiChannel extends ApiClient {
  constructor() {
    super('whapi_channels', { accountScoped: true });
  }

  create(params) {
    return axios.post(this.url, params);
  }

  getQrCode(inboxId) {
    return axios.get(`${this.url}/${inboxId}/qr_code`);
  }
}

export default new WhapiChannel();
