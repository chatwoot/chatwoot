/* global axios */
import ApiClient from './ApiClient';

class SearchAPI extends ApiClient {
  constructor() {
    super('search', { accountScoped: true });
  }

  get({ q }) {
    return axios.get(this.url, {
      params: {
        q,
      },
    });
  }
}

export default new SearchAPI();
