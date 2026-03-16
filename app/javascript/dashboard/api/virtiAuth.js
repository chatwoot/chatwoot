/* global axios */
import { reactive } from 'vue';

const TOKEN_TTL_MS = 60 * 1000;

const authState = reactive({
  token: null,
  expiresAt: null,
  available: false,
});

// Cache de inbox_id -> id_robo (vive enquanto a pagina esta aberta)
const roboCache = {};

const clearAuthState = () => {
  Object.assign(authState, {
    token: null,
    expiresAt: null,
    available: false,
  });
  // Limpa cache de robos ao perder a sessao
  Object.keys(roboCache).forEach(k => delete roboCache[k]);
};

const setAuthState = token => {
  Object.assign(authState, {
    token,
    expiresAt: Date.now() + TOKEN_TTL_MS,
    available: true,
  });
};

const isExpired = () => !authState.expiresAt || authState.expiresAt <= Date.now();

const fetchToken = async () => {
  try {
    const response = await axios.get('/api/v1/virti/auth');
    const { token } = response?.data || {};
    if (!token) {
      clearAuthState();
      return null;
    }
    setAuthState(token);
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

/**
 * Resolve o id_robo correto para uma inbox.
 * Usa cache em memoria — so chama o endpoint na primeira vez por inbox.
 * @param {number} inboxId - O inbox_id da conversa ativa
 * @returns {Promise<number|null>} O id_robo ou null se nao encontrar
 */
const resolveRobo = async inboxId => {
  if (!inboxId) return null;

  const cacheKey = String(inboxId);
  if (roboCache[cacheKey]) return roboCache[cacheKey];

  try {
    const response = await axios.get(
      `/api/v1/virti/resolve-robo?inbox_id=${inboxId}`
    );
    const idRobo = response?.data?.id_robo;
    if (idRobo) {
      roboCache[cacheKey] = idRobo;
      return idRobo;
    }
    return null;
  } catch {
    return null;
  }
};

const getAvailability = () => authState.available;

export default {
  ensureToken,
  clearAuthState,
  getAvailability,
  resolveRobo,
};
