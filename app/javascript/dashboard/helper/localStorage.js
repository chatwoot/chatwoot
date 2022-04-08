class LocalStorage {
  constructor(key) {
    this.key = key;
  }

  store(allItems) {
    localStorage.setItem(this.key, JSON.stringify(allItems));
    localStorage.setItem(this.key + ':ts', Date.now());
  }

  get() {
    let stored = localStorage.getItem(this.key);
    return JSON.parse(stored) || [];
  }
}

export default LocalStorage;
