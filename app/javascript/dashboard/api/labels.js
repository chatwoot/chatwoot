import CacheEnabledApiClient from './CacheEnabledApiClient';

class LabelsAPI extends CacheEnabledApiClient {
  constructor() {
    super('labels', { accountScoped: true });
  }

  get cacheModelName() {
    return 'label';
  }
}

export default new LabelsAPI();
