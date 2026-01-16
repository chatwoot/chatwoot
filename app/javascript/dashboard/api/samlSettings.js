/* global axios */
import ApiClient from './ApiClient';

class SamlSettingsAPI extends ApiClient {
  constructor() {
    super('saml_settings', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  create(data) {
    return axios.post(this.url, { saml_settings: data });
  }

  update(data) {
    return axios.put(this.url, { saml_settings: data });
  }

  delete() {
    return axios.delete(this.url);
  }
}

export default new SamlSettingsAPI();
