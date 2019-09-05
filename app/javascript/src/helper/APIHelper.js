/* eslint no-console: 0 */
import constants from '../constants';
import Auth from '../api/auth';
import router from '../routes';

const parseErrorCode = error => {
  if (error.response) {
    // 901, 902 are used to identify billing related issues
    if ([901, 902].includes(error.response.status)) {
      const name = Auth.isAdmin() ? 'billing' : 'billing_deactivated';
      router.push({ name });
    }
  }
  return Promise.reject(error);
};

export default axios => {
  const wootApi = axios.create();
  wootApi.defaults.baseURL = constants.apiURL;
  // Add Auth Headers to requests if logged in
  if (Auth.isLoggedIn()) {
    Object.assign(wootApi.defaults.headers.common, Auth.getAuthData());
  }
  // Response parsing interceptor
  wootApi.interceptors.response.use(
    response => response,
    error => parseErrorCode(error)
  );
  return wootApi;
};
