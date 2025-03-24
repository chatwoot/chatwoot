import { LocalStorage } from './localStorage';

const DEFAULT_EXPIRY = 3 * 60 * 60 * 1000; // 3 hours in milliseconds

export const getFromCache = (key, expiry = DEFAULT_EXPIRY) => {
  try {
    const cached = LocalStorage.get(key);
    if (!cached) return null;

    const { data, timestamp } = cached;
    const isExpired = Date.now() - timestamp > expiry;

    if (isExpired) {
      LocalStorage.remove(key);
      return null;
    }

    return data;
  } catch (error) {
    return null;
  }
};

export const setCache = (key, data) => {
  try {
    const cacheData = {
      data,
      timestamp: Date.now(),
    };
    LocalStorage.set(key, cacheData);
  } catch (error) {
    // Ignore cache errors
  }
};

export const clearCache = key => {
  try {
    LocalStorage.remove(key);
  } catch (error) {
    // Ignore cache errors
  }
};
