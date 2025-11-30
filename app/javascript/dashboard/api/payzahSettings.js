/* global axios */
import ApiClient from './ApiClient';

class PayzahSettingsAPI extends ApiClient {
  constructor() {
    super('payzah_settings', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  create(data) {
    return axios.post(this.url, { payzah_settings: data });
  }

  update(data) {
    return axios.put(this.url, { payzah_settings: data });
  }

  delete() {
    return axios.delete(this.url);
  }
}

export default new PayzahSettingsAPI();
