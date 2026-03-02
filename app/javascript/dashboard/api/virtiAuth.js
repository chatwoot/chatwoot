/* global axios */
import { reactive } from 'vue';

const TOKEN_TTL_MS = 60 * 1000;

const authState = reactive({
  token: null,
  idRobo: null,
  expiresAt: null,
  available: false,
});

const clearAuthState = () => {
  Object.assign(authState, {
    token: null,
    idRobo: null,
    expiresAt: null,
    available: false,
  });
};

const setAuthState = (token, idRobo) => {
  Object.assign(authState, {
    token,
    idRobo,
    expiresAt: Date.now() + TOKEN_TTL_MS,
    available: true,
  });
};

const isExpired = () => !authState.expiresAt || authState.expiresAt <= Date.now();

const fetchToken = async () => {
  try {
    const response = await axios.get('/api/v1/virti/auth');
    const { token, id_robo: idRobo } = response?.data || {};
    if (!token) {
      clearAuthState();
      return null;
    }
    setAuthState(token, idRobo);
    return token;
  } catch {
    clearAuthState();
    return null;
  }
};

const ensureToken = async () => {
  if (authState.token && !isExpired()) {
    return authState.token;
  }
  return fetchToken();
};

const getAvailability = () => authState.available;
const getIdRobo = () => authState.idRobo;

export default {
  ensureToken,
  clearAuthState,
  getAvailability,
  getIdRobo,
};
