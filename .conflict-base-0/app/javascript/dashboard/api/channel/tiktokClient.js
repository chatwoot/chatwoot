/* global axios */
import ApiClient from '../ApiClient';

class TiktokChannel extends ApiClient {
  constructor() {
    super('tiktok', { accountScoped: true });
  }

  generateAuthorization(payload) {
    return axios.post(`${this.url}/authorization`, payload);
  }
}

export default new TiktokChannel();
