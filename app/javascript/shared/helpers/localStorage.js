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

  remove(key) {
    window.localStorage.removeItem(key);
    window.localStorage.removeItem(key + ':ts');
  },
};
