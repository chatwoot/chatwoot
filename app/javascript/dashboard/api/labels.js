/* global axios */
import CacheEnabledApiClient from './CacheEnabledApiClient';

class LabelsAPI extends CacheEnabledApiClient {
  constructor() {
    super('labels', { accountScoped: true });
  }

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    return 'label';
  }

  pin(labelId) {
    return axios.post(`${this.url}/${labelId}/pin`);
  }

  unpin(labelId) {
    return axios.delete(`${this.url}/${labelId}/pin`);
  }
}

export default new LabelsAPI();
