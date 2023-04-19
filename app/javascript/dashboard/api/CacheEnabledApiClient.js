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
    await this.dataManager.initDb();

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
    await this.dataManager.initDb();
    const response = await axios.get(this.url);
    this.dataManager.replace({
      modelName: this.cacheModelName,
      data: this.extractDataFromResponse(response),
    });

    await this.dataManager.setCacheKeys({
      [this.cacheModelName]: newKey,
    });

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
