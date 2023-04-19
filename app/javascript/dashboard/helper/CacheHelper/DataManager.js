import { openDB } from 'idb';
import { DATA_VERSION } from './version';

export class DataManager {
  constructor(accountId) {
    this.modelsToSync = ['inbox', 'label', 'team'];
    this.accountId = accountId;
    this.db = null;
  }

  async initDb() {
    if (this.db) return this.db;
    this.db = await openDB(`cw-store-${this.accountId}`, DATA_VERSION, {
      upgrade(db) {
        db.createObjectStore('cache-keys');
        db.createObjectStore('inbox', { keyPath: 'id' });
        db.createObjectStore('label', { keyPath: 'id' });
        db.createObjectStore('team', { keyPath: 'id' });
      },
    });

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

    this.db.clear(modelName);
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
