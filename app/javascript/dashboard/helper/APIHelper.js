import Cookies from 'js-cookie';
import { differenceInDays } from 'date-fns';
import Auth from '../api/auth';
import { getHeaderExpiry } from '../store/utils/api';

const parseErrorCode = error => Promise.reject(error);

export default axios => {
  const { apiHost = '' } = window.chatwootConfig || {};
  const wootApi = axios.create({ baseURL: `${apiHost}/` });

  const syncAuthHeaders = () => {
    if (!Auth.hasAuthCookie()) return;

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
  };

  syncAuthHeaders();

  wootApi.interceptors.request.use(config => {
    syncAuthHeaders();
    return config;
  });

  wootApi.interceptors.response.use(
    response => {
      if (response.headers?.['access-token']) {
        const expiryDate = getHeaderExpiry(response);
        Cookies.set('cw_d_session_info', JSON.stringify(response.headers), {
          expires: differenceInDays(expiryDate, new Date()),
        });
        syncAuthHeaders();
      }
      return response;
    },
    error => parseErrorCode(error)
  );
  return wootApi;
};
