/* global axios */
import ApiClient from './ApiClient';

class CsatTemplatesAPI extends ApiClient {
  constructor() {
    super('csat_templates', { accountScoped: true });
  }

  get({ page } = {}) {
    return axios.get(this.url, {
      params: {
        page,
      },
    });
  }

  getTemplate(id) {
    return axios.get(`${this.url}/${id}`);
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  create(params) {
    return axios.post(this.url, params);
  }

  update(id, params) {
    return axios.patch(`${this.url}/${id}`, params);
  }

  getInboxes() {
    return axios.get(`${this.url}/inboxes`);
  }
}

export default new CsatTemplatesAPI();
