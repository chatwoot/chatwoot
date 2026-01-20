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

  contacts({ q }) {
    return axios.get(`${this.url}/contacts`, {
      params: {
        q,
      },
    });
  }

  conversations({ q }) {
    return axios.get(`${this.url}/conversations`, {
      params: {
        q,
      },
    });
  }

  messages({ q, page = 1 }) {
    return axios.get(`${this.url}/messages`, {
      params: {
        q,
        page,
      },
    });
  }
}

export default new SearchAPI();
