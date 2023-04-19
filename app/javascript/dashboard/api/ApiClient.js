/* global axios */

const DEFAULT_API_VERSION = 'v1';

class ApiClient {
  constructor(resource, options = {}) {
    this.apiVersion = `/api/${options.apiVersion || DEFAULT_API_VERSION}`;
    this.options = options;
    this.resource = resource;
  }

  get url() {
    return `${this.baseUrl()}/${this.resource}`;
  }

  // eslint-disable-next-line class-methods-use-this
  get accountIdFromRoute() {
    const isInsideAccountScopedURLs = window.location.pathname.includes(
      '/app/accounts'
    );

    if (isInsideAccountScopedURLs) {
      return window.location.pathname.split('/')[3];
    }

    return '';
  }

  baseUrl() {
    let url = this.apiVersion;

    if (this.options.enterprise) {
      url = `/enterprise${url}`;
    }

    if (this.options.accountScoped && this.accountIdFromRoute) {
      url = `${url}/accounts/${this.accountIdFromRoute}`;
    }

    return url;
  }

  get() {
    return axios.get(this.url);
  }

  show(id) {
    return axios.get(`${this.url}/${id}`);
  }

  create(data) {
    return axios.post(this.url, data);
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, data);
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}

export default ApiClient;
