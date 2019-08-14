/* global axios */

import endPoints from './endPoints';

export default {
  getSubscription() {
    const urlData = endPoints('subscriptions').get();
    const fetchPromise = new Promise((resolve, reject) => {
      axios.get(urlData.url)
      .then((response) => {
        resolve(response);
      })
      .catch((error) => {
        reject(error);
      });
    });
    return fetchPromise;
  },
};
