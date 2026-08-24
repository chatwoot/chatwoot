import axios from 'axios';

const getAccountScopedUrl = (accountId, path) =>
  `/api/v1/accounts/${accountId}${path}`;

export default {
  getProviders(accountId) {
    return axios.get(getAccountScopedUrl(accountId, '/whisker_ai/providers'));
  },
  createProvider(accountId, params) {
    return axios.post(getAccountScopedUrl(accountId, '/whisker_ai/providers'), { provider: params });
  },
  updateProvider(accountId, id, params) {
    return axios.put(getAccountScopedUrl(accountId, `/whisker_ai/providers/${id}`), { provider: params });
  },
  deleteProvider(accountId, id) {
    return axios.delete(getAccountScopedUrl(accountId, `/whisker_ai/providers/${id}`));
  },
  setPrimary(accountId, id) {
    return axios.post(getAccountScopedUrl(accountId, `/whisker_ai/providers/${id}/set_primary`));
  },
};
