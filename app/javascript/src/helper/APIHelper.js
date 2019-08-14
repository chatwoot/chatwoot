/* eslint no-console: 0 */
import constants from '../constants';
import Auth from '../api/auth';
import router from '../routes';

const parseErrorCode = (error) => {
  if (error.response) {
    if (error.response.status === 401) {
      // If auth failed

    } else if (error.response.status === 500) {
      // If server failed

    } else if (error.response.status === 422) {
      // If request params are errored

    } else if (error.response.status === 901 || error.response.status === 902) {
      let name = 'billing_deactivated';
      if (Auth.isAdmin()) {
        name = 'billing';
      }
      // If Trial ended
      router.push({ name });
    } else {
      // Anything else
    }
  } else {
    // Something happened in setting up the request that triggered an Error

  }
  // Do something with request error
  return Promise.reject(error);
};

export default (axios) => {
  const wootApi = axios.create();
  wootApi.defaults.baseURL = constants.apiURL;
  // Add Auth Headers to requests if logged in
  if (Auth.isLoggedIn()) {
    Object.assign(wootApi.defaults.headers.common, Auth.getAuthData());
  }
  // Response parsing interceptor
  wootApi.interceptors.response.use(response => response, error => parseErrorCode(error));
  return wootApi;
};
