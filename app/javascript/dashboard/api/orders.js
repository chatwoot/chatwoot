/* global axios */

const create = (accountId, conversationId, orderData) => {
  return axios.post(
    `/api/v1/accounts/${accountId}/conversations/${conversationId}/orders`,
    orderData
  );
};

const get = (accountId, page = 1, filters = {}, sort = '', order = '') => {
  const params = new URLSearchParams({ page: page.toString() });

  if (filters.status && filters.status !== 'all') {
    params.append('status', filters.status);
  }
  if (filters.dateRange && filters.dateRange !== 'all') {
    params.append('date_range', filters.dateRange);
  }
  if (filters.dateFrom) {
    params.append('date_from', filters.dateFrom);
  }
  if (filters.dateTo) {
    params.append('date_to', filters.dateTo);
  }
  if (filters.search) {
    params.append('search', filters.search);
  }
  if (sort) {
    params.append('sort', `${order}${sort}`);
  }

  return axios.get(`/api/v1/accounts/${accountId}/orders?${params.toString()}`);
};

const search = (accountId, searchQuery, page = 1, sort = '', order = '') => {
  const params = new URLSearchParams({
    page: page.toString(),
    q: searchQuery,
  });

  if (sort) {
    params.append('sort', `${order}${sort}`);
  }

  return axios.get(
    `/api/v1/accounts/${accountId}/orders/search?${params.toString()}`
  );
};

export default {
  create,
  get,
  search,
};
