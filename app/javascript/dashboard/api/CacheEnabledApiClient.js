/* global axios */
import { DataManager } from '../../worker/data-manager';
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
    const cachekey = await this.dataManager.getCacheKey(this.cacheModelName);
    const { data } = await axios.get(
      `/api/v1/accounts/${this.accountIdFromRoute}`
    );

    const cacheKeyFromApi = data.cache_keys[this.cacheModelName];

    let localData = [];

    if (cacheKeyFromApi === cachekey) {
      localData = await this.dataManager.get({
        modelName: this.cacheModelName,
      });
    }

    if (localData.length === 0) {
      this.dataManager.setCacheKeys({ [this.cacheModelName]: cacheKeyFromApi });
      return this.refetchAndCommit();
    }

    return this.marshallData(localData);
  }

  async refetchAndCommit() {
    await this.dataManager.initDb();
    const response = await axios.get(this.url);
    this.dataManager.replace({
      modelName: this.cacheModelName,
      data: this.extractDataFromResponse(response),
    });

    return response;
  }
}

export default CacheEnabledApiClient;
