import ApiClient from './ApiClient';

class LocationsAPI extends ApiClient {
  constructor() {
    super('locations', { accountScoped: true });
  }
}

export default new LocationsAPI();
