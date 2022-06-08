import Cookies from 'js-cookie';
import axios from 'axios';

export const hasAuthCookie = () => {
  return !!Cookies.getJSON('cw_d_session_info');
};

export const getAuthData = () => {
  if (hasAuthCookie()) {
    return Cookies.getJSON('cw_d_session_info');
  }
  return false;
};

export const parseErrorCode = error => Promise.reject(error);

export const createAxiosClient = () => {
  const { apiHost = '' } = window.chatwootConfig || {};
  const wootApi = axios.create({ baseURL: `${apiHost}/` });
  // Add Auth Headers to requests if logged in
  if (hasAuthCookie()) {
    const {
      'access-token': accessToken,
      'token-type': tokenType,
      client,
      expiry,
      uid,
    } = getAuthData();
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
