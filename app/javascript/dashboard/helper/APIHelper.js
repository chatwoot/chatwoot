/* eslint no-console: 0 */
import constants from '../constants';
import Auth from '../api/auth';

const parseErrorCode = error => {
  return Promise.reject(error);
};

export default axios => {
  const wootApi = axios.create();
  wootApi.defaults.baseURL = constants.apiURL;
  // Add Auth Headers to requests if logged in
  if (Auth.isLoggedIn()) {
    const {
      'access-token': accessToken,
      'token-type': tokenType,
      client,
      expiry,
      uid,
    } = Auth.getAuthData();
    Object.assign(wootApi.defaults.headers.common, {
      'access-token': accessToken,
      'token-type': tokenType,
      client,
      expiry,
      uid,
    });
  }
  // Response parsing interceptor
  wootApi.interceptors.response.use(
    response => response,
    error => parseErrorCode(error)
  );
  return wootApi;
};
