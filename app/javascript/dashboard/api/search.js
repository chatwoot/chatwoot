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

  contacts({ q, page = 1, since, until }) {
    return axios.get(`${this.url}/contacts`, {
      params: {
        q,
        page: page,
        since,
        until,
      },
    });
  }

  conversations({ q, page = 1, since, until }) {
    return axios.get(`${this.url}/conversations`, {
      params: {
        q,
        page: page,
        since,
        until,
      },
    });
  }

  messages({ q, page = 1, since, until, from, inboxId }) {
    return axios.get(`${this.url}/messages`, {
      params: {
        q,
        page: page,
        since,
        until,
        from,
        inbox_id: inboxId,
      },
    });
  }

  articles({ q, page = 1, since, until }) {
    return axios.get(`${this.url}/articles`, {
      params: {
        q,
        page: page,
        since,
        until,
      },
    });
  }
}

export default new SearchAPI();
