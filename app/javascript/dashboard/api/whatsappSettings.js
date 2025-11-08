/* global axios */
import ApiClient from './ApiClient';

class WhatsappSettingsAPI extends ApiClient {
  constructor() {
    super('whatsapp_settings', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  create(data) {
    return axios.post(this.url, { whatsapp_settings: data });
  }

  update(data) {
    return axios.put(this.url, { whatsapp_settings: data });
  }

  delete() {
    return axios.delete(this.url);
  }
}

export default new WhatsappSettingsAPI();
