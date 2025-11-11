/* global axios */
import ApiClient from './ApiClient';

export const buildCompanyParams = (page, sort, search) => {
  let params = `page=${page}`;
  if (sort) {
    params = `${params}&sort=${sort}`;
  }
  if (search) {
    params = `${params}&search=${search}`;
  }
  return params;
};

class CompanyAPI extends ApiClient {
  constructor() {
    super('companies', { accountScoped: true });
  }

  get(page, sort = 'name', search = '') {
    let requestURL = `${this.url}?${buildCompanyParams(page, sort, search)}`;
    return axios.get(requestURL);
  }

  search(search = '', page = 1, sort = 'name') {
    // Use the index endpoint with search query parameter
    return this.get(page, sort, search);
  }
}

export default new CompanyAPI();
