/* eslint no-console: 0 */
/* global axios */
/* eslint no-undef: "error" */
/* eslint no-unused-expressions: ["error", { "allowShortCircuit": true }] */
import endPoints from './endPoints';

export default {
  // Get Inbox related to the account
  createChannel(channel, channelParams) {
    const urlData = endPoints('createChannel')(channel, channelParams);
    return axios.post(urlData.url, urlData.params);
  },

  addAgentsToChannel(inboxId, agentsId) {
    const urlData = endPoints('addAgentsToChannel');
    urlData.params.inbox_id = inboxId;
    urlData.params.user_ids = agentsId;
    return axios.post(urlData.url, urlData.params);
  },

  fetchFacebookPages(token) {
    const urlData = endPoints('fetchFacebookPages');
    urlData.params.omniauth_token = token;
    return axios.post(urlData.url, urlData.params);
  },
};
