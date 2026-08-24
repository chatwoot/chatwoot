import axios from 'axios';

const getAccountScopedUrl = (accountId, path) =>
  `/api/v1/accounts/${accountId}${path}`;

export default {
  getFlows(accountId) {
    return axios.get(
      getAccountScopedUrl(accountId, '/conversation_flows')
    );
  },
  createFlow(accountId, params) {
    return axios.post(
      getAccountScopedUrl(accountId, '/conversation_flows'),
      { conversation_flow: params }
    );
  },
  updateFlow(accountId, id, params) {
    return axios.put(
      getAccountScopedUrl(accountId, `/conversation_flows/${id}`),
      { conversation_flow: params }
    );
  },
  deleteFlow(accountId, id) {
    return axios.delete(
      getAccountScopedUrl(accountId, `/conversation_flows/${id}`)
    );
  },
  toggleFlow(accountId, id) {
    return axios.post(
      getAccountScopedUrl(accountId, `/conversation_flows/${id}/toggle`)
    );
  },
};
