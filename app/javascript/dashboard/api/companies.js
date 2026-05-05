/* global axios */
import ApiClient from './ApiClient';

const buildParams = params =>
  new URLSearchParams(
    Object.entries(params).filter(
      ([key, value]) => value !== undefined && (value !== '' || key === 'q')
    )
  ).toString();

class CompanyAPI extends ApiClient {
  constructor() {
    super('companies', { accountScoped: true });
  }

  get(params = {}) {
    const { page = 1, sort = 'name' } = params;
    const requestURL = `${this.url}?${buildParams({ page, sort })}`;
    return axios.get(requestURL);
  }

  search(query = '', page = 1, sort = 'name') {
    const requestURL = `${this.url}/search?${buildParams({ q: query, page, sort })}`;
    return axios.get(requestURL);
  }

  listContacts(id, page = 1) {
    return axios.get(`${this.url}/${id}/contacts?${buildParams({ page })}`);
  }

  searchContacts(id, query = '', page = 1) {
    const requestURL = `${this.url}/${id}/contacts/search?${buildParams({ q: query, page })}`;
    return axios.get(requestURL);
  }

  createContact(id, payload) {
    return axios.post(`${this.url}/${id}/contacts`, payload);
  }

  removeContact(id, contactId) {
    return axios.delete(`${this.url}/${id}/contacts/${contactId}`);
  }

  destroyCustomAttributes(id, customAttributes) {
    return axios.post(`${this.url}/${id}/destroy_custom_attributes`, {
      custom_attributes: customAttributes,
    });
  }

  destroyAvatar(id) {
    return axios.delete(`${this.url}/${id}/avatar`);
  }
}

export default new CompanyAPI();
