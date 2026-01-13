import Auth from '../api/auth';

const parseErrorCode = error => {
  if (
    error?.response?.status === 401 &&
    error?.response?.data?.error === 'Account is suspended'
  ) {
    const accountId = window.location.pathname.split('/')[3];
    if (accountId && !window.location.pathname.includes('/suspended')) {
      window.location = `/app/accounts/${accountId}/suspended`;
    }
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
