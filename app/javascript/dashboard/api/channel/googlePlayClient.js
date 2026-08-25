/* global axios */
import ApiClient from '../ApiClient';

class GooglePlayClient extends ApiClient {
  constructor() {
    super('google_play', { accountScoped: true });
  }

  generateAuthorization(payload) {
    return axios.post(`${this.url}/authorization`, payload);
  }
}

export default new GooglePlayClient();
