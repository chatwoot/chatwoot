/* eslint no-console: 0 */
/* global axios */
/* eslint no-undef: "error" */
/* eslint no-unused-expressions: ["error", { "allowShortCircuit": true }] */
import endPoints from './endPoints';

export default {
  fetchFacebookPages(token, accountId) {
    const urlData = endPoints('fetchFacebookPages');
    urlData.params.omniauth_token = token;
    return axios.post(urlData.url(accountId), urlData.params);
  },
};
