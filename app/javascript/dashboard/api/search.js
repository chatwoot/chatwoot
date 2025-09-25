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

  contacts({ q, page = 1 }) {
    return axios.get(`${this.url}/contacts`, {
      params: {
        q,
        page: page,
      },
    });
  }

  conversations({ q, page = 1 }) {
    return axios.get(`${this.url}/conversations`, {
      params: {
        q,
        page: page,
      },
    });
  }

  messages({ q, page = 1 }) {
    return axios.get(`${this.url}/messages`, {
      params: {
        q,
        page: page,
      },
    });
  }

  articles({ q, page = 1 }) {
    return axios.get(`${this.url}/articles`, {
      params: {
        q,
        page: page,
      },
    });
  }
}

export default new SearchAPI();
