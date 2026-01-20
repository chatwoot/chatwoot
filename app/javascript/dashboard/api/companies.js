/* global axios */
import ApiClient from './ApiClient';

export const buildCompanyParams = (page, sort) => {
  let params = `page=${page}`;
  if (sort) {
    params = `${params}&sort=${sort}`;
  }
  return params;
};

export const buildSearchParams = (query, page, sort) => {
  let params = `q=${encodeURIComponent(query)}&page=${page}`;
  if (sort) {
    params = `${params}&sort=${sort}`;
  }
  return params;
};

class CompanyAPI extends ApiClient {
  constructor() {
    super('companies', { accountScoped: true });
  }

  get(params = {}) {
    const { page = 1, sort = 'name' } = params;
    const requestURL = `${this.url}?${buildCompanyParams(page, sort)}`;
    return axios.get(requestURL);
  }

  search(query = '', page = 1, sort = 'name') {
    const requestURL = `${this.url}/search?${buildSearchParams(query, page, sort)}`;
    return axios.get(requestURL);
  }
}

export default new CompanyAPI();
