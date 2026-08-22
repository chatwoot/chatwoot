/* global axios */
import CacheEnabledApiClient from './CacheEnabledApiClient';

class CannedResponse extends CacheEnabledApiClient {
  constructor() {
    super('canned_responses', { accountScoped: true });
  }

  get(options = {}) {
    if (options === true || options.cache) {
      return super.get(true);
    }

    const { searchKey, usable } = options;
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

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    return 'canned_response';
  }

  // The index endpoint returns a bare array instead of a payload wrapper
  // eslint-disable-next-line class-methods-use-this
  extractDataFromResponse(response) {
    return response.data;
  }

  // eslint-disable-next-line class-methods-use-this
  marshallData(dataToParse) {
    return { data: dataToParse };
  }
}

export default new CannedResponse();
