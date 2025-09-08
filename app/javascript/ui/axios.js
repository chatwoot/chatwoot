const parseErrorCode = error => Promise.reject(error);

export default axios => {
  // eslint-disable-next-line no-underscore-dangle
  const apiHost = window.__WOOT_API_HOST__;
  // eslint-disable-next-line no-underscore-dangle
  const accessToken = window.__WOOT_ACCESS_TOKEN__;
  const wootApi = axios.create({ baseURL: `${apiHost}/` });

  Object.assign(wootApi.defaults.headers.common, {
    api_access_token: accessToken,
  });

  wootApi.interceptors.response.use(
    response => response,
    error => parseErrorCode(error)
  );
  return wootApi;
};
