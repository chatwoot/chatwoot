/* global axios */
import ApiClient from './ApiClient';

class LocationsAPI extends ApiClient {
  constructor() {
    super('locations', { accountScoped: true });
  }

  getUserLocations() {
    return axios.get(`${this.url}/user_locations`);
  }
}

export default new LocationsAPI();
