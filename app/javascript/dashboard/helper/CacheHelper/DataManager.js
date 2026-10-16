import { openDB } from 'idb';
import { DATA_VERSION, INBOX_CACHE_INVALIDATION_VERSION } from './version';

export class DataManager {
  constructor(accountId) {
    this.modelsToSync = ['inbox', 'label', 'team', 'canned_response'];
    this.accountId = accountId;
    this.db = null;
  }

  async initDb() {
    if (this.db) return this.db;
    const dbName = `cw-store-${this.accountId}`;

    let rejectBlocked;
    const blockedByAnotherTab = new Promise((_, reject) => {
      rejectBlocked = reject;
    });

    const opening = openDB(dbName, DATA_VERSION, {
      upgrade(db, oldVersion, _newVersion, transaction) {
        const shouldInvalidateInboxCache =
          oldVersion > 0 && oldVersion < INBOX_CACHE_INVALIDATION_VERSION;

        if (shouldInvalidateInboxCache) {
          transaction.objectStore('inbox').clear();
          transaction.objectStore('cache-keys').delete('inbox');
        }

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
      // Another tab still holds this database at an older version and never
      // closes its connection (a tab left open across a deploy). A blocked
      // open neither resolves nor rejects, so awaiting it would stall the
      // caller forever; reject instead, and callers such as
      // CacheEnabledApiClient fall back to the network on a rejected initDb.
      blocked() {
        rejectBlocked(
          new Error(
            `Opening ${dbName} is blocked by another tab holding an older version`
          )
        );
      },
      // A newer tab is waiting to upgrade and this connection is in its way:
      // close it so that upgrade can proceed instead of stalling that tab
      // the same way.
      blocking() {
        opening.then(db => db.close());
      },
    });

    try {
      this.db = await Promise.race([opening, blockedByAnotherTab]);
    } catch (error) {
      // A blocked open stays pending in the background; if the other tab
      // eventually closes and it goes through, close that connection again.
      // Nothing adopted it, and leaving it open would block the next upgrade.
      opening.then(
        db => {
          if (this.db !== db) db.close();
        },
        () => {}
      );
      throw error;
    }

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
