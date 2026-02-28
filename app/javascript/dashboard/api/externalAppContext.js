/* global axios */

import ApiClient from './ApiClient';

class ExternalAppContextAPI extends ApiClient {
  constructor() {
    super('external_app_context', { accountScoped: true });
  }

  fetch(params = {}) {
    return axios.get(this.url, { params });
  }
}

export default new ExternalAppContextAPI();
