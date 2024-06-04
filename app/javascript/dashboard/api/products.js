/* global axios */
import ApiClient from './ApiClient';

export const buildContactParams = (page, sortAttr, search) => {
  let params = `page=${page}&sort=${sortAttr}`;
  if (search) {
    params = `${params}&q=${search}`;
  }
  return params;
};

class ProductAPI extends ApiClient {
  constructor() {
    super('products', { accountScoped: true });
  }

  get(page, sortAttr = 'name') {
    let requestURL = `${this.url}?${buildContactParams(page, sortAttr, '')}`;
    return axios.get(requestURL);
  }

  search(search = '', page = 1, sortAttr = 'name') {
    let requestURL = `${this.url}/search?${buildContactParams(
      page,
      sortAttr,
      search
    )}`;
    return axios.get(requestURL);
  }
}

export default new ProductAPI();
