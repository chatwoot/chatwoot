/* global axios */

import endPoints from './endPoints';

export default {
  getAccountReports(metric, from, to) {
    const { url } = endPoints('reports').account(metric, from, to);
    return axios.get(url);
  },
  getAccountSummary(accountId, from, to) {
    const urlData = endPoints('reports').accountSummary(accountId, from, to);
    return axios.get(urlData.url);
  },
};
