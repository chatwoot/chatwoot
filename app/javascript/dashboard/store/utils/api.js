import fromUnixTime from 'date-fns/fromUnixTime';
import differenceInDays from 'date-fns/differenceInDays';
import { deleteDB, openDB } from 'idb';
import Cookies from 'js-cookie';
import { withIndexedDBTimeout } from 'dashboard/helper/CacheHelper/timeout';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { SESSION_STORAGE_KEYS } from 'dashboard/constants/sessionStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import SessionStorage from 'shared/helpers/sessionStorage';
import { emitter } from 'shared/helpers/mitt';
import {
  ANALYTICS_IDENTITY,
  ANALYTICS_RESET,
  CHATWOOT_RESET,
  CHATWOOT_SET_USER,
} from '../../constants/appEvents';

Cookies.defaults = { sameSite: 'Lax' };

export const getLoadingStatus = state => state.fetchAPIloadingStatus;
export const setLoadingStatus = (state, status) => {
  state.fetchAPIloadingStatus = status;
};

export const setUser = user => {
  emitter.emit(CHATWOOT_SET_USER, { user });
  emitter.emit(ANALYTICS_IDENTITY, { user });
};

export const getHeaderExpiry = response =>
  fromUnixTime(response.headers.expiry);

export const setAuthCredentials = response => {
  const expiryDate = getHeaderExpiry(response);
  Cookies.set('cw_d_session_info', JSON.stringify(response.headers), {
    expires: differenceInDays(expiryDate, new Date()),
  });
  setUser(response.data.data, expiryDate);
};

export const clearBrowserSessionCookies = () => {
  Cookies.remove('cw_d_session_info');
  Cookies.remove('auth_data');
  Cookies.remove('user');
};

export const clearLocalStorageOnLogout = () => {
  LocalStorage.remove(LOCAL_STORAGE_KEYS.DRAFT_MESSAGES);
};

export const clearSessionStorageOnLogout = () => {
  SessionStorage.remove(SESSION_STORAGE_KEYS.IMPERSONATION_USER);
};

const deleteDatabase = dbName =>
  new Promise(resolve => {
    deleteDB(dbName, {
      blocked: () => resolve(false),
    }).then(
      () => resolve(true),
      () => resolve(false)
    );
  });

const clearDatabase = async dbName => {
  let database;
  try {
    database = await openDB(dbName);
    const storeNames = [...database.objectStoreNames];
    if (!storeNames.length) return;

    const transaction = database.transaction(storeNames, 'readwrite');
    await Promise.all(
      storeNames.map(storeName => transaction.objectStore(storeName).clear())
    );
    await transaction.done;
  } finally {
    database?.close();
  }
};

const clearAndDeleteDatabase = async dbName => {
  // Clearing removes the current session's cache even if another tab blocks
  // deletion. The queued delete remains best-effort so data written later by
  // that stale tab is removed when it eventually releases the connection.
  try {
    await clearDatabase(dbName);
  } catch {
    // A failed clear must not prevent deletion from completing the cleanup.
  }
  return deleteDatabase(dbName);
};

export const deleteIndexedDBOnLogout = async () => {
  let dbs = [];
  try {
    dbs = await window.indexedDB.databases();
    dbs = dbs.map(db => db.name);
  } catch (e) {
    dbs = JSON.parse(localStorage.getItem('cw-idb-names') || '[]');
  }

  const chatwootDatabases = dbs.filter(dbName =>
    dbName?.startsWith('cw-store-')
  );
  const deletionResults = await Promise.all(
    chatwootDatabases.map(dbName =>
      // A prior blocked delete can hold this database's connection queue. Do
      // not let that browser-owned request delay logout indefinitely.
      withIndexedDBTimeout(clearAndDeleteDatabase(dbName)).catch(() => false)
    )
  );

  if (deletionResults.every(Boolean)) {
    localStorage.removeItem('cw-idb-names');
  }
};

export const clearCookiesOnLogout = () => {
  emitter.emit(CHATWOOT_RESET);
  emitter.emit(ANALYTICS_RESET);
  clearBrowserSessionCookies();
  clearLocalStorageOnLogout();
  clearSessionStorageOnLogout();
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
  if (error?.response?.data?.errors) {
    return error?.response?.data?.errors[0];
  }
  return error;
};

export const throwErrorMessage = error => {
  const errorMessage = parseAPIErrorResponse(error);
  throw new Error(errorMessage);
};

export const parseLinearAPIErrorResponse = (error, defaultMessage) => {
  const errorData = error.response.data;
  const errorMessage = errorData?.error?.errors?.[0]?.message || defaultMessage;
  return errorMessage;
};
