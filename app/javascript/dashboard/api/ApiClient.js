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
    const isInsideAccountScopedURLs =
      window.location.pathname.includes('/app/accounts');

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
  fetchCampaignContacts(id) {
    const data = axios.get(`${this.url}/${id}/fetchCampaignContacts`); // Use `const` to define the variable
    return data;
  }

  show(id) {
    return axios.get(`${this.url}/${id}`);
  }

  create(data) {
    return axios.post(this.url, data);
  }

  update(id, data) {
    const endpoint = `${this.url}/${id}`;

    return axios.patch(endpoint, data).catch(error => {
      throw error;
    });
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}

export default ApiClient;
