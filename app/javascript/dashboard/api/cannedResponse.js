/* global axios */
import CacheEnabledApiClient from './CacheEnabledApiClient';

class CannedResponse extends CacheEnabledApiClient {
  constructor() {
    super('canned_responses', { accountScoped: true });
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

  get(options = {}) {
    if (options === true || options === false) {
      return super.get(options);
    }

    const { searchKey, all = false, inboxId = null } = options;
    const params = new URLSearchParams();
    if (searchKey) params.append('search', searchKey);
    if (all) params.append('all', true);
    if (inboxId) params.append('inbox_id', inboxId);
    const query = params.toString();
    return axios.get(query ? `${this.url}?${query}` : this.url);
  }
}

export default new CannedResponse();
