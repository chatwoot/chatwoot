/* global axios */

import ApiClient from './ApiClient';

class SlaAPI extends ApiClient {
  constructor() {
    super('sla_policies', { accountScoped: true });
  }

  get({ page }) {
    const url = page ? `${this.url}?page=${page}` : this.url;
    return axios.get(url);
  }
}

export default new SlaAPI();
