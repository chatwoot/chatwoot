/* global axios */
import ApiClient from './ApiClient';

class SearchAPI extends ApiClient {
  constructor() {
    super('search', { accountScoped: true });
  }

  get({ q }) {
    return axios.get(this.url, { params: { q } });
  }

  counts({ q, types, since, until, from, inboxId }, { signal } = {}) {
    return axios.get(`${this.url}/counts`, {
      signal,
      params: { q, types, since, until, from, inbox_id: inboxId },
    });
  }

  contacts({ q, page = 1, perPage, since, until }, { signal } = {}) {
    return axios.get(`${this.url}/contacts`, {
      signal,
      params: { q, page, per_page: perPage, since, until },
    });
  }

  conversations({ q, page = 1, perPage, since, until }, { signal } = {}) {
    return axios.get(`${this.url}/conversations`, {
      signal,
      params: { q, page, per_page: perPage, since, until },
    });
  }

  messages(
    { q, page = 1, perPage, since, until, from, inboxId },
    { signal } = {}
  ) {
    return axios.get(`${this.url}/messages`, {
      signal,
      params: {
        q,
        page,
        per_page: perPage,
        since,
        until,
        from,
        inbox_id: inboxId,
      },
    });
  }

  articles({ q, page = 1, perPage, since, until }, { signal } = {}) {
    return axios.get(`${this.url}/articles`, {
      signal,
      params: { q, page, per_page: perPage, since, until },
    });
  }
}

export default new SearchAPI();
