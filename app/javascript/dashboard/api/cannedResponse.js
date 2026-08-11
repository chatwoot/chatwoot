/* global axios */

import ApiClient from './ApiClient';

class CannedResponse extends ApiClient {
  constructor() {
    super('canned_responses', { accountScoped: true });
  }

  get({ searchKey, signal } = {}) {
    return axios.get(this.url, {
      params: searchKey ? { search: searchKey } : undefined,
      signal,
    });
  }
}

export default new CannedResponse();
