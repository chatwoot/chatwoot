import ApiClient from './ApiClient';

export const buildOrdersParams = (page, sortAttr, search) => {
  let params = `page=${page}&sort=${sortAttr}`;
  if (search) {
    params = `${params}&q=${search}`;
  }

  return params;
};

class IntegrationsOrderAPI extends ApiClient {
  constructor() {
    super('orders', { accountScoped: true });
  }

  get(page, sortAttr = 'name') {
    let requestURL = `${this.url}?${buildOrdersParams(page, sortAttr, '')}`;
    return axios.get(requestURL);
  }

  update() {
    return axios.put(`${this.baseUrl()}/custom_apis/update_all_orders`);
  }

  search(search = '', page = 1, sortAttr = 'order_number') {
    let requestURL = `${this.url}/search?${buildOrdersParams(
      page,
      sortAttr,
      search
    )}`;
    return axios.get(requestURL);
  }

  filter(page = 1, sortAttr = 'order_number', queryPayload) {
    let requestURL = `${this.url}/filter?${buildOrdersParams(page, sortAttr)}`;
    return axios.post(requestURL, queryPayload);
  }

  contactOrders(contactId) {
    let requestURL = `${this.url}/contact_order?contact_id=${contactId}`;
    return axios.get(requestURL);
  }
}

export default new IntegrationsOrderAPI();
