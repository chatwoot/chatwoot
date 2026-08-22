import Auth from '../api/auth';

const handleUnauthorizedError = error => {
  if (error?.response?.status === 401) {
    // Avoid redirect loop if already on login
    if (!window.location.pathname.includes('/app/login')) {
      window.location.assign('/app/login');
    }
  }
  return Promise.reject(error);
};

const parseErrorCode = error => handleUnauthorizedError(error);

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
