/* eslint no-console: 0 */
/* global axios */
/* eslint no-undef: "error" */
/* eslint no-unused-expressions: ["error", { "allowShortCircuit": true }] */
import endPoints from '../endPoints';

export default {
  sendMessage([conversationId, message]) {
    const urlData = endPoints('sendMessage')(conversationId, message);
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .post(urlData.url, urlData.params)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },

  addPrivateNote([conversationId, message]) {
    const urlData = endPoints('addPrivateNote')(conversationId, message);
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .post(urlData.url, urlData.params)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },

  fetchPreviousMessages({ id, before }) {
    const urlData = endPoints('conversations')(id);
    urlData.params.before = before;
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .get(urlData.url, {
          params: urlData.params,
        })
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
