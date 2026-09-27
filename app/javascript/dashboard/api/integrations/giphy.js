/* global axios */

import ApiClient from '../ApiClient';

class GiphyAPI extends ApiClient {
  constructor() {
    super('integrations/giphy', { accountScoped: true });
  }

  search({ query, offset = 0, signal } = {}) {
    return axios.get(`${this.url}/search`, {
      params: { q: query || undefined, offset },
      signal,
    });
  }
}

export default new GiphyAPI();
