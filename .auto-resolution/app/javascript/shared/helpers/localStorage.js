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
    window.localStorage.setItem(key + ':ts', Date.now().toString());
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

  updateJsonStore(storeName, key, value) {
    try {
      const storedValue = this.get(storeName) || {};
      storedValue[key] = value;
      this.set(storeName, storedValue);
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error('Error updating JSON store in localStorage', e);
    }
  },

  getFromJsonStore(storeName, key) {
    try {
      const storedValue = this.get(storeName) || {};
      return storedValue[key] || null;
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error('Error getting value from JSON store in localStorage', e);
      return null;
    }
  },

  deleteFromJsonStore(storeName, key) {
    try {
      const storedValue = this.get(storeName);
      if (storedValue && key in storedValue) {
        delete storedValue[key];
        this.set(storeName, storedValue);
      }
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error('Error deleting entry from JSON store in localStorage', e);
    }
  },
};
