import { openDB } from 'idb';
import { DATA_VERSION } from './version';

export class DataManager {
  constructor(accountId) {
    this.modelsToSync = ['inbox', 'labels'];
    this.accountId = accountId;
    this.db = null;
  }

  async getDb() {
    if (this.db) return this.db;
    this.db = await openDB(`cw-store-${this.accountId}`, DATA_VERSION, {
      upgrade(db) {
        db.createObjectStore('cache-keys');
        db.createObjectStore('inbox', { keyPath: 'id' });
        db.createObjectStore('labels', { keyPath: 'id' });
      },
    });

    return this.db;
  }

  async validateModel(name) {
    if (!name) throw new Error('Model name is not defined');
    if (!this.modelsToSync.includes(name)) {
      throw new Error(`Model ${name} is not defined`);
    }
  }

  async push({ modelName, data }) {
    this.validateModel(modelName);

    const db = await this.getDb();
    if (Array.isArray(data)) {
      const tx = db.transaction(modelName, 'readwrite');
      data.forEach(item => {
        tx.store.add(item);
      });
      await tx.done;
    } else {
      await db.add(modelName, data);
    }
  }

  async get({ modelName }) {
    this.validateModel(modelName);

    const db = await this.getDb();
    return db.getAll(modelName);
  }

  async setCacheKey(cacheKeys) {
    const db = await this.getDb();
    Object.keys(cacheKeys).forEach(async modelName => {
      db.put('cache-keys', cacheKeys[modelName], modelName);
    });
  }

  async getCacheKey(modelName) {
    this.validateModel(modelName);

    const db = await this.getDb();
    return db.get('cache-keys', modelName);
  }
}
