import axios from 'axios';

const getAccountScopedUrl = (accountId, path) =>
  `/api/v1/accounts/${accountId}${path}`;

export default {
  getInstalled(accountId) {
    return axios.get(getAccountScopedUrl(accountId, '/whisker_themes'));
  },
  install(accountId, themeId) {
    return axios.post(getAccountScopedUrl(accountId, '/whisker_themes'), { theme_id: themeId });
  },
  setActive(accountId, themeId) {
    return axios.put(getAccountScopedUrl(accountId, `/whisker_themes/${themeId}/activate`));
  },
  remove(accountId, themeId) {
    return axios.delete(getAccountScopedUrl(accountId, `/whisker_themes/${themeId}`));
  },
};
