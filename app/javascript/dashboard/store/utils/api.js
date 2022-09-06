import fromUnixTime from 'date-fns/fromUnixTime';
import differenceInDays from 'date-fns/differenceInDays';
import Cookies from 'js-cookie';
import {
  ANALYTICS_IDENTITY,
  ANALYTICS_RESET,
  CHATWOOT_RESET,
  CHATWOOT_SET_USER,
} from '../../helper/scriptHelpers';

Cookies.defaults = { sameSite: 'Lax' };

export const getLoadingStatus = state => state.fetchAPIloadingStatus;
export const setLoadingStatus = (state, status) => {
  state.fetchAPIloadingStatus = status;
};

export const setUser = user => {
  window.bus.$emit(CHATWOOT_SET_USER, { user });
  window.bus.$emit(ANALYTICS_IDENTITY, { user });
};

export const getHeaderExpiry = response =>
  fromUnixTime(response.headers.expiry);

export const setAuthCredentials = response => {
  const expiryDate = getHeaderExpiry(response);
  Cookies.set('cw_d_session_info', response.headers, {
    expires: differenceInDays(expiryDate, new Date()),
  });
  setUser(response.data.data, expiryDate);
};

export const clearBrowserSessionCookies = () => {
  Cookies.remove('cw_d_session_info');
  Cookies.remove('auth_data');
  Cookies.remove('user');
};

export const clearCookiesOnLogout = () => {
  window.bus.$emit(CHATWOOT_RESET);
  window.bus.$emit(ANALYTICS_RESET);
  clearBrowserSessionCookies();
  const globalConfig = window.globalConfig || {};
  const logoutRedirectLink = globalConfig.LOGOUT_REDIRECT_LINK || '/';
  window.location = logoutRedirectLink;
};

export const parseAPIErrorResponse = error => {
  if (error?.response?.data?.message) {
    return error?.response?.data?.message;
  }
  if (error?.response?.data?.error) {
    return error?.response?.data?.error;
  }
  return error;
};

export const throwErrorMessage = error => {
  const errorMessage = parseAPIErrorResponse(error);
  throw new Error(errorMessage);
};
