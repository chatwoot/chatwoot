/**
 * Page <-> Service Worker auth bridge backed by IndexedDB.
 *
 * The PWA service worker needs valid DeviseTokenAuth credentials to be able to
 * post replies (and mark notifications as read) directly from a notification
 * action — including when the PWA tab is not currently open. We persist the
 * minimum auth context to IndexedDB so the worker can read it on demand.
 *
 * IMPORTANT: This stores tokens, not passwords. The cookie used by the host
 * page (`cw_d_session_info`) already contains these same tokens, so this is
 * not a meaningful escalation of risk — it merely makes them readable from the
 * service worker context which lives in the same origin.
 */
import Cookies from 'js-cookie';

export const PWA_AUTH_DB_NAME = 'chatwit-pwa-auth';
export const PWA_AUTH_STORE = 'sessions';
export const PWA_AUTH_KEY = 'current';
const DB_VERSION = 1;

const isSupported = () =>
  typeof indexedDB !== 'undefined' && typeof window !== 'undefined';

const openDatabase = () =>
  new Promise((resolve, reject) => {
    if (!isSupported()) {
      reject(new Error('IndexedDB unavailable'));
      return;
    }
    const request = indexedDB.open(PWA_AUTH_DB_NAME, DB_VERSION);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(PWA_AUTH_STORE)) {
        db.createObjectStore(PWA_AUTH_STORE);
      }
    };
    request.onerror = () => reject(request.error);
    request.onsuccess = () => resolve(request.result);
  });

const withStore = async (mode, fn) => {
  const db = await openDatabase();
  return new Promise((resolve, reject) => {
    const tx = db.transaction(PWA_AUTH_STORE, mode);
    const store = tx.objectStore(PWA_AUTH_STORE);
    let result;
    tx.oncomplete = () => {
      db.close();
      resolve(result);
    };
    tx.onerror = () => {
      db.close();
      reject(tx.error);
    };
    Promise.resolve(fn(store))
      .then(value => {
        result = value;
      })
      .catch(reject);
  });
};

export const readSession = async () => {
  if (!isSupported()) return null;
  try {
    return await withStore(
      'readonly',
      store =>
        new Promise((resolve, reject) => {
          const req = store.get(PWA_AUTH_KEY);
          req.onsuccess = () => resolve(req.result || null);
          req.onerror = () => reject(req.error);
        })
    );
  } catch {
    return null;
  }
};

export const writeSession = async session => {
  if (!isSupported()) return false;
  try {
    await withStore('readwrite', store => {
      store.put(session, PWA_AUTH_KEY);
    });
    return true;
  } catch {
    return false;
  }
};

export const clearSession = async () => {
  if (!isSupported()) return false;
  try {
    await withStore('readwrite', store => {
      store.delete(PWA_AUTH_KEY);
    });
    return true;
  } catch {
    return false;
  }
};

const SESSION_COOKIE = 'cw_d_session_info';

export const buildSessionFromCookie = ({ accountId, userId } = {}) => {
  const raw = Cookies.get(SESSION_COOKIE);
  if (!raw) return null;
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return null;
  }
  if (!parsed || !parsed['access-token']) return null;

  return {
    credentials: {
      accessToken: parsed['access-token'],
      tokenType: parsed['token-type'] || 'Bearer',
      client: parsed.client,
      expiry: parsed.expiry,
      uid: parsed.uid,
    },
    accountId: accountId ?? null,
    userId: userId ?? null,
    origin: window.location.origin,
    updatedAt: Date.now(),
  };
};

export const syncSessionToServiceWorker = async ({
  accountId,
  userId,
} = {}) => {
  const session = buildSessionFromCookie({ accountId, userId });
  if (!session) return false;
  const ok = await writeSession(session);
  if (!ok) return false;
  if (
    typeof navigator !== 'undefined' &&
    navigator.serviceWorker &&
    navigator.serviceWorker.controller
  ) {
    try {
      navigator.serviceWorker.controller.postMessage({
        type: 'PWA_AUTH_UPDATED',
        accountId: session.accountId,
      });
    } catch {
      // postMessage is best-effort; the SW reads from IDB on demand.
    }
  }
  return true;
};
