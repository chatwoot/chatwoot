import axios from 'axios';

const getAccountScopedUrl = (accountId, path) =>
  `/api/v1/accounts/${accountId}${path}`;

export default {
  getEntries(accountId) {
    return axios.get(
      getAccountScopedUrl(accountId, '/knowledge_bases')
    );
  },
  createEntry(accountId, params) {
    return axios.post(
      getAccountScopedUrl(accountId, '/knowledge_bases'),
      { knowledge_base: params }
    );
  },
  updateEntry(accountId, id, params) {
    return axios.put(
      getAccountScopedUrl(accountId, `/knowledge_bases/${id}`),
      { knowledge_base: params }
    );
  },
  deleteEntry(accountId, id) {
    return axios.delete(
      getAccountScopedUrl(accountId, `/knowledge_bases/${id}`)
    );
  },
  search(accountId, query, limit = 5) {
    return axios.get(
      getAccountScopedUrl(accountId, '/knowledge_bases/search'),
      { params: { q: query, limit } }
    );
  },
};
