/* global axios */
import ApiClient from './ApiClient';

class CatalogSettingsAPI extends ApiClient {
  constructor() {
    super('catalog_settings', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  create(data) {
    return axios.post(this.url, { catalog_settings: data });
  }

  update(data) {
    return axios.put(this.url, { catalog_settings: data });
  }
}

export default new CatalogSettingsAPI();
