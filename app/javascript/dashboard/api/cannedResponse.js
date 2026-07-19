/* global axios */

import ApiClient from './ApiClient';

class CannedResponse extends ApiClient {
  constructor() {
    super('canned_responses', { accountScoped: true });
  }

  get({ searchKey, usable } = {}) {
    const params = {};
    if (searchKey) params.search = searchKey;
    if (usable) params.usable = true;
    return axios.get(this.url, { params });
  }

  approve(id, { visibility }) {
    return axios.post(`${this.url}/${id}/approve`, { visibility });
  }

  reject(id) {
    return axios.post(`${this.url}/${id}/reject`);
  }
}

export default new CannedResponse();
