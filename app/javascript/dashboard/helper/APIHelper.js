import Auth from '../api/auth';
import Cookies from 'js-cookie';
import { BUS_EVENTS } from '../../shared/constants/busEvents';

const parseErrorCode = error => {
  // eslint-disable-next-line eqeqeq
  if (error.response.status == 402) {
    if (error?.response?.data?.error) {
      Cookies.set('subscription', error.response.data.error);
    } else {
      Cookies.set(
        'subscription',
        'Account limit exceeded. Upgrade to a higher plan\n'
      );
    }
    // bus.$emit(BUS_EVENTS.SHOW_PLAN_MODAL);
  }
  return Promise.reject(error);
};

export default axios => {
  const { apiHost = '' } = window.chatwootConfig || {};
  const wootApi = axios.create({ baseURL: `${apiHost}/` });
  // Add Auth Headers to requests if logged in
  if (Auth.hasAuthCookie()) {
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
