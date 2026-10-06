/* global axios */
const AUTHORIZATION_URL = '/api/v1/oauth/authorization';
const CONNECTED_APPS_URL = '/api/v1/profile/oauth_applications';

export default {
  getAuthorization(params) {
    return axios.get(AUTHORIZATION_URL, { params });
  },
  approveAuthorization(params) {
    return axios.post(AUTHORIZATION_URL, params);
  },
  denyAuthorization(params) {
    return axios.delete(AUTHORIZATION_URL, { params });
  },
  getConnectedApps() {
    return axios.get(CONNECTED_APPS_URL);
  },
  revokeConnectedApp(id) {
    return axios.delete(`${CONNECTED_APPS_URL}/${id}`);
  },
};
