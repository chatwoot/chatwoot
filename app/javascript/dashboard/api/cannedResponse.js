/* eslint no-console: 0 */
/* global axios */
/* eslint no-undef: "error" */
/* eslint no-unused-expressions: ["error", { "allowShortCircuit": true }] */
import endPoints from './endPoints';

export default {
  getAllCannedResponses() {
    const urlData = endPoints('cannedResponse').get();
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

  searchCannedResponse({ searchKey }) {
    let urlData = endPoints('cannedResponse').get();
    urlData = `${urlData.url}?search=${searchKey}`;
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .get(urlData)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },

  addCannedResponse(cannedResponseObj) {
    const urlData = endPoints('cannedResponse').post();
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .post(urlData.url, cannedResponseObj)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },
  editCannedResponse(cannedResponseObj) {
    const urlData = endPoints('cannedResponse').put(cannedResponseObj.id);
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .put(urlData.url, cannedResponseObj)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },
  deleteCannedResponse(responseId) {
    const urlData = endPoints('cannedResponse').delete(responseId);
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .delete(urlData.url)
        .then(response => {
          resolve(response);
        })
        .catch(error => {
          reject(Error(error));
        });
    });
    return fetchPromise;
  },
  getLabels() {
    const urlData = endPoints('fetchLabels');
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
  // Get Inbox related to the account
  getInboxes() {
    const urlData = endPoints('fetchInboxes');
    const fetchPromise = new Promise((resolve, reject) => {
      axios
        .get(urlData.url)
        .then(response => {
          console.log('fetch inboxes success');
          resolve(response);
        })
        .catch(error => {
          console.log('fetch inboxes failure');
          reject(Error(error));
        });
    });
    return fetchPromise;
  },
};
