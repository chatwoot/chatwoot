/* global axios */
import virtiAuth from './virtiAuth';

const VIRTI_API_PREFIX = '/virti-api';

const request = async (method, path, options = {}) => {
  const token = await virtiAuth.ensureToken();
  if (!token) {
    return Promise.reject(new Error('Virti backend unavailable'));
  }
  try {
    return await axios({
      method,
      url: `${VIRTI_API_PREFIX}${path}`,
      ...options,
      headers: {
        ...(options.headers || {}),
        Authorization: token,
      },
    });
  } catch (error) {
    if (error?.response?.status === 401) {
      virtiAuth.clearAuthState();
    }
    throw error;
  }
};

export const virtiGet = (path, params) => request('get', path, { params });
export const virtiPost = (path, data) => request('post', path, { data });
export const virtiPut = (path, data) => request('put', path, { data });
export const virtiPatch = (path, data) => request('patch', path, { data });
export const virtiDelete = path => request('delete', path);
export const getVirtiAvailability = () => virtiAuth.getAvailability();
