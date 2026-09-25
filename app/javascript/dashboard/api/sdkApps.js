import ApiClient from './ApiClient';

class SdkAppsAPI extends ApiClient {
  constructor() {
    super('sdk_apps', { accountScoped: true });
  }
}

export default new SdkAppsAPI();
