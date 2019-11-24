/* global axios */

import endPoints from './endPoints';

export default {
  getAccountReports(metric, from, to) {
    const urlData = endPoints('reports').account(metric, from, to);
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .get(urlData.url)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },
  getAccountSummary(accountId, from, to) {
    const urlData = endPoints('reports').accountSummary(accountId, from, to);
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .get(urlData.url)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },
};
