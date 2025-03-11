/* global axios */

import ApiClient from './ApiClient';

class CannedResponse extends ApiClient {
  constructor() {
    super('canned_responses', { accountScoped: true });
  }

  get({ searchKey, inboxId }) {
    const params = new URLSearchParams();

    if (searchKey) {
      params.append('search', searchKey);
    }
    if (inboxId) {
      params.append('inbox_id', inboxId);
    }

    return axios.get(`${this.url}?${params.toString()}`);
  }
}

export default new CannedResponse();
