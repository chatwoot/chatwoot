/* eslint no-console: 0 */
/* global axios */
/* eslint no-undef: "error" */
/* eslint no-unused-expressions: ["error", { "allowShortCircuit": true }] */
import endPoints from './endPoints';

export default {
  // Get Inbox related to the account
  createFBChannel(channel, channelParams) {
    const urlData = endPoints('createFBChannel')(channel, channelParams);
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

  createEmailChannel: async params => {
    const urlData = endPoints('createEmailChannel')(params);
    try {
      const response = await axios.post(urlData.url, urlData.params);
      return response;
    } catch (error) {
      return Error(error);
    }
  },

  addAgentsToChannel(inboxId, agentsId) {
    const urlData = endPoints('addAgentsToChannel');
    urlData.params.inbox_id = inboxId;
    urlData.params.user_ids = agentsId;
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

  fetchFacebookPages(token) {
    const urlData = endPoints('fetchFacebookPages');
    urlData.params.omniauth_token = token;
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
};
