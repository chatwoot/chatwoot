export const LocalStorage = {
  clearAll() {
    window.localStorage.clear();
  },

  get(key) {
    let value = null;
    try {
      value = window.localStorage.getItem(key);
      return typeof value === 'string' ? JSON.parse(value) : value;
    } catch (error) {
      return value;
    }
  },

  set(key, value) {
    if (typeof value === 'object') {
      window.localStorage.setItem(key, JSON.stringify(value));
    } else {
      window.localStorage.setItem(key, value);
    }
    window.localStorage.setItem(key + ':ts', Date.now());
  },

  setFlag(store, accountId, key, expiry = 24 * 60 * 60 * 1000) {
    const storeName = accountId ? `${store}::${accountId}` : store;

    const rawValue = window.localStorage.getItem(storeName);
    const parsedValue = rawValue ? JSON.parse(rawValue) : {};

    parsedValue[key] = Date.now() + expiry;

    window.localStorage.setItem(storeName, JSON.stringify(parsedValue));
  },

  getFlag(store, accountId, key) {
    const storeName = store ? `${store}::${accountId}` : store;

    const rawValue = window.localStorage.getItem(storeName);
    const parsedValue = rawValue ? JSON.parse(rawValue) : {};

    return parsedValue[key] && parsedValue[key] > Date.now();
  },

  remove(key) {
    window.localStorage.removeItem(key);
    window.localStorage.removeItem(key + ':ts');
  },
};
