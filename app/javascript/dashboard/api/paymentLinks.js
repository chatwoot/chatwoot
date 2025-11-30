/* global axios */

const create = (accountId, conversationId, paymentData) => {
  return axios.post(
    `/api/v1/accounts/${accountId}/conversations/${conversationId}/payment_links`,
    paymentData
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
  if (filters.amountMin) {
    params.append('amount_min', filters.amountMin);
  }
  if (filters.amountMax) {
    params.append('amount_max', filters.amountMax);
  }
  if (sort) {
    params.append('sort', `${order}${sort}`);
  }

  return axios.get(
    `/api/v1/accounts/${accountId}/payment_links?${params.toString()}`
  );
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
    `/api/v1/accounts/${accountId}/payment_links/search?${params.toString()}`
  );
};

const filter = (accountId, queryPayload, page = 1, sort = '', order = '') => {
  const params = new URLSearchParams({ page: page.toString() });

  if (sort) {
    params.append('sort', `${order}${sort}`);
  }

  return axios.post(
    `/api/v1/accounts/${accountId}/payment_links/filter?${params.toString()}`,
    queryPayload
  );
};

const exportPaymentLinks = accountId => {
  return axios.post(`/api/v1/accounts/${accountId}/payment_links/export`);
};

export default {
  create,
  get,
  search,
  filter,
  exportPaymentLinks,
};
