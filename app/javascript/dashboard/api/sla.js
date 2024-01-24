/* global axios */

import ApiClient from './ApiClient';

class SLA extends ApiClient {
  constructor() {
    super('sla', { accountScoped: true });
  }

  get({ page }) {
    const url = page ? `${this.url}?page=${page}` : this.url;
    return axios.get(url);
  }
}

export default new SLA();
