import endPoints from './endPoints';

export default {
  fetchFacebookPages(token, accountId) {
    const urlData = endPoints('fetchFacebookPages');
    urlData.params.omniauth_token = token;
    return this.axios.post(urlData.url(accountId), urlData.params);
  },
};
