/* global axios */
import { DataManager } from '../helper/CacheHelper/DataManager';
import ApiClient from './ApiClient';

class CacheEnabledApiClient extends ApiClient {
  constructor(resource, options = {}) {
    super(resource, options);
    this.accountDataManager = null;
  }

  // These clients are module level singletons, so they are constructed before the router
  // has settled on an account: a boot at /app redirects to /app/accounts/:id without
  // re-evaluating the bundle. Resolving the store once in the constructor therefore pointed
  // every account at a single `cw-store-` database, where a shared default cache key could
  // hand one account another's rows. The account has to come from the route at read time.
  get dataManager() {
    const accountId = this.accountIdFromRoute;

    if (this.accountDataManager?.accountId !== accountId) {
      this.accountDataManager = new DataManager(accountId);
    }

    return this.accountDataManager;
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

  // Whether this resource's cached rows are only valid under a key that came with the body
  // itself. Opt in when the payload depends on the build that served it, and the key from
  // /cache_keys therefore cannot vouch for it.
  // eslint-disable-next-line class-methods-use-this
  get usesResponseBoundCacheKey() {
    return false;
  }

  // The cache key a resource sends with its own body, when it sends one.
  // eslint-disable-next-line class-methods-use-this, no-unused-vars
  cacheKeyFromResponse(_response) {
    return null;
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

    const { data } = await axios.get(
      `/api/v1/accounts/${this.accountIdFromRoute}/cache_keys`
    );
    const cacheKeyFromApi = data.cache_keys[this.cacheModelName];
    const isCacheValid = await this.validateCacheKey(cacheKeyFromApi);

    let localData = [];
    if (isCacheValid) {
      localData = await this.dataManager.get({
        modelName: this.cacheModelName,
      });
    }

    if (localData.length === 0) {
      return this.refetchAndCommit(cacheKeyFromApi);
    }

    return this.marshallData(localData);
  }

  async refetchAndCommit(newKey = null) {
    const response = await this.getFromNetwork();
    const boundKey = this.cacheKeyFromResponse(response);

    // No key on a resource that requires one means an older build answered this request,
    // which during a rolling deploy is exactly when the key from /cache_keys belongs to a
    // different build. Borrowing it would file this payload under a fingerprint that
    // outlives the rollout and never expires. Nothing is cached; the caller still gets the
    // fresh response, and the next read tries again against a worker that sends the key.
    if (this.usesResponseBoundCacheKey && boundKey === null) return response;

    try {
      await this.dataManager.initDb();

      await this.dataManager.replace({
        modelName: this.cacheModelName,
        data: this.extractDataFromResponse(response),
      });

      await this.dataManager.setCacheKeys({
        [this.cacheModelName]: boundKey ?? newKey,
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
