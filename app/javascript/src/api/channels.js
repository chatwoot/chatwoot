/* eslint no-console: 0 */
/* global axios */
/* eslint no-undef: "error" */
/* eslint no-unused-expressions: ["error", { "allowShortCircuit": true }] */
import endPoints from './endPoints';

export default {
  // Get Inbox related to the account
  createChannel(channel, channelParams) {
    const urlData = endPoints('createChannel')(channel, channelParams);
    const fetchPromise = new Promise((resolve, reject) => {
      axios.post(urlData.url, urlData.params)
      .then((response) => {
        resolve(response);
      })
      .catch((error) => {
        reject(Error(error));
      });
    });
    return fetchPromise;
  },

  addAgentsToChannel(inboxId, agentsId) {
    const urlData = endPoints('addAgentsToChannel');
    urlData.params.inbox_id = inboxId;
    urlData.params.user_ids = agentsId;
    const fetchPromise = new Promise((resolve, reject) => {
      axios.post(urlData.url, urlData.params)
      .then((response) => {
        resolve(response);
      })
      .catch((error) => {
        reject(Error(error));
      });
    });
    return fetchPromise;
  },

  fetchFacebookPages(token) {
    const urlData = endPoints('fetchFacebookPages');
    urlData.params.omniauth_token = token;
    const fetchPromise = new Promise((resolve, reject) => {
      axios.post(urlData.url, urlData.params)
      .then((response) => {
        resolve(response);
      })
      .catch((error) => {
        reject(Error(error));
      });
    });
    return fetchPromise;
  },
};
