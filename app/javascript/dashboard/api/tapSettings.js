/* global axios */
import ApiClient from './ApiClient';

class TapSettingsAPI extends ApiClient {
  constructor() {
    super('tap_settings', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  create(data) {
    return axios.post(this.url, { tap_settings: data });
  }

  update(data) {
    return axios.put(this.url, { tap_settings: data });
  }

  delete() {
    return axios.delete(this.url);
  }
}

export default new TapSettingsAPI();
