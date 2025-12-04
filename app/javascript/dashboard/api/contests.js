import ApiClient from './ApiClient';

class ContestsAPI extends ApiClient {
  constructor() {
    super('contests', { accountScoped: true });
  }

  index(params = {}) {
    return window.axios.get(this.url, { params });
  }

  create(payload, meta = {}) {
    return window.axios.post(this.url, { contest: payload, ...meta });
  }

  update(id, payload, meta = {}) {
    return window.axios.put(`${this.url}/${id}`, {
      contest: payload,
      ...meta,
    });
  }

  delete(id, params = {}) {
    return window.axios.delete(`${this.url}/${id}`, {
      params,
    });
  }

  report(params = {}) {
    return window.axios.get(`${this.url}/report`, { params });
  }
}

export default new ContestsAPI();
