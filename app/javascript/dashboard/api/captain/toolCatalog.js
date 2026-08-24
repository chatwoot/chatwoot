/* global axios */
import ApiClient from '../ApiClient';

class CaptainToolCatalog extends ApiClient {
  constructor() {
    super('captain/tool_catalog', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  show(providerKey) {
    return axios.get(`${this.url}/${providerKey}`);
  }

  install(data) {
    return axios.post(`${this.url}/installations`, {
      installation: data,
    });
  }

  showInstallation(id) {
    return axios.get(`${this.url}/installations/${id}`);
  }

  reconnect(providerKey, data = {}) {
    return axios.post(`${this.url}/${providerKey}/reconnect`, {
      reconnect: data,
    });
  }

  update(providerKey, templates) {
    return axios.post(`${this.url}/${providerKey}/update`, {
      update: { templates },
    });
  }
}

export default new CaptainToolCatalog();
