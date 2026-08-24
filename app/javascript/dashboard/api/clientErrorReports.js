import axios from 'axios';

const getAccountScopedUrl = (accountId, path) =>
  `/api/v1/accounts/${accountId}${path}`;

export default {
  getReports(accountId, params = {}) {
    return axios.get(getAccountScopedUrl(accountId, '/client_error_reports'), { params });
  },
  getReport(accountId, id) {
    return axios.get(getAccountScopedUrl(accountId, `/client_error_reports/${id}`));
  },
};
