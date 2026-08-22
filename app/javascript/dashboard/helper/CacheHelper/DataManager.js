import { openDB } from 'idb';
import { DATA_VERSION } from './version';

// An IndexedDB version bump stays pending while any other tab still holds an
// older-version connection. Without a deadline the awaiting API client never
// settles and the dashboard spins on "loading inboxes" forever.
const IDB_OPEN_TIMEOUT_MS = 3000;

export class DataManager {
  constructor(accountId) {
    this.modelsToSync = ['inbox', 'label', 'team', 'canned_response'];
    this.accountId = accountId;
    this.db = null;
  }

  async initDb() {
    if (this.db) return this.db;
    const dbName = `cw-store-${this.accountId}`;
    this.db = await Promise.race([
      openDB(dbName, DATA_VERSION, {
        upgrade(db) {
          // Existing databases already carry the stores added in earlier versions,
          // and createObjectStore throws on a name that is already taken.
          const createStore = (name, options) => {
            if (db.objectStoreNames.contains(name)) return;
            db.createObjectStore(name, options);
          };

          createStore('cache-keys');
          createStore('inbox', { keyPath: 'id' });
          createStore('label', { keyPath: 'id' });
          createStore('team', { keyPath: 'id' });
          createStore('canned_response', { keyPath: 'id' });
        },
        blocking(event) {
          // Release this connection so another tab's schema upgrade can proceed.
          event.target.close();
        },
      }),
      new Promise((resolve, reject) => {
        setTimeout(
          () => reject(new Error('IndexedDB open timed out')),
          IDB_OPEN_TIMEOUT_MS
        );
      }),
    ]);

    // Store the database name in LocalStorage
    const dbNames = JSON.parse(localStorage.getItem('cw-idb-names') || '[]');
    if (!dbNames.includes(dbName)) {
      dbNames.push(dbName);
      localStorage.setItem('cw-idb-names', JSON.stringify(dbNames));
    }

    return this.db;
  }

  validateModel(name) {
    if (!name) throw new Error('Model name is not defined');
    if (!this.modelsToSync.includes(name)) {
      throw new Error(`Model ${name} is not defined`);
    }
    return true;
  }

  async replace({ modelName, data }) {
    this.validateModel(modelName);

    await this.db.clear(modelName);
    return this.push({ modelName, data });
  }

  async push({ modelName, data }) {
    this.validateModel(modelName);

    if (Array.isArray(data)) {
      const tx = this.db.transaction(modelName, 'readwrite');
      data.forEach(item => {
        tx.store.add(item);
      });
      await tx.done;
    } else {
      await this.db.add(modelName, data);
    }
  }

  async get({ modelName }) {
    this.validateModel(modelName);
    return this.db.getAll(modelName);
  }

  async setCacheKeys(cacheKeys) {
    Object.keys(cacheKeys).forEach(async modelName => {
      this.db.put('cache-keys', cacheKeys[modelName], modelName);
    });
  }

  async getCacheKey(modelName) {
    this.validateModel(modelName);

    return this.db.get('cache-keys', modelName);
  }
}
