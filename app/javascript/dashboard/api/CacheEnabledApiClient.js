/* global axios */
import { DataManager } from '../helper/CacheHelper/DataManager';
import ApiClient from './ApiClient';

class CacheEnabledApiClient extends ApiClient {
  constructor(resource, options = {}) {
    super(resource, options);
    this.dataManager = new DataManager(this.accountIdFromRoute);
  }

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    throw new Error('cacheModelName is not defined');
  }

  get(cache = false) {
    if (cache) {
      return this.getFromCache();
    }

    return this.getFromNetwork();
  }

  getFromNetwork() {
    return axios.get(this.url);
  }

  // eslint-disable-next-line class-methods-use-this
  extractDataFromResponse(response) {
    return response.data.payload;
  }

  // eslint-disable-next-line class-methods-use-this
  marshallData(dataToParse) {
    return { data: { payload: dataToParse } };
  }

  async getFromCache() {
    try {
      // IDB is not supported in Firefox private mode: https://bugzilla.mozilla.org/show_bug.cgi?id=781982
      await this.dataManager.initDb();
    } catch {
      return this.getFromNetwork();
    }

    // Trust the IDB cache. Freshness is maintained by:
    //   - boot-time hydrateStoresFromCache (compares server keys once on boot)
    //   - ActionCable ACCOUNT_CACHE_INVALIDATED broadcasts (live updates)
    //   - ReconnectService.revalidateCaches (on WebSocket reconnect)
    // Skipping the per-call /cache_keys preflight eliminates N GET requests per
    // cold settings-page load.
    const localData = await this.dataManager.get({
      modelName: this.cacheModelName,
    });

    if (localData.length > 0) {
      return this.marshallData(localData);
    }

    // Empty IDB (first load or wiped): seed from network using whatever local
    // cache key we have (null when never seen). refetchAndCommit handles null.
    const localKey = await this.dataManager.getCacheKey(this.cacheModelName);
    return this.refetchAndCommit(localKey);
  }

  async refetchAndCommit(newKey = null) {
    const response = await this.getFromNetwork();

    try {
      await this.dataManager.initDb();

      // Await replace so data is persisted before the cache key is — otherwise
      // a concurrent reader could see a fresh key paired with stale data.
      await this.dataManager.replace({
        modelName: this.cacheModelName,
        data: this.extractDataFromResponse(response),
      });

      await this.dataManager.setCacheKeys({
        [this.cacheModelName]: newKey,
      });
    } catch {
      // Ignore error
    }

    return response;
  }

  async validateCacheKey(cacheKeyFromApi) {
    if (!this.dataManager.db) {
      await this.dataManager.initDb();
    }

    const cachekey = await this.dataManager.getCacheKey(this.cacheModelName);
    return cacheKeyFromApi === cachekey;
  }
}

export default CacheEnabledApiClient;
