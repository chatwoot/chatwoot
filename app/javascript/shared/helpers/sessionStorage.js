export default {
  clearAll() {
    window.sessionStorage.clear();
  },

  get(key) {
    try {
      const value = window.sessionStorage.getItem(key);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      return window.sessionStorage.getItem(key);
    }
  },

  set(key, value) {
    if (typeof value === 'object') {
      window.sessionStorage.setItem(key, JSON.stringify(value));
    } else {
      window.sessionStorage.setItem(key, value);
    }
  },

  remove(key) {
    window.sessionStorage.removeItem(key);
  },
};
