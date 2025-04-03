/* global axios */
import ApiClient from '../ApiClient';

class InstagramChannel extends ApiClient {
  constructor() {
    super('instagram', { accountScoped: true });
  }

  generateAuthorization(payload) {
    return axios.post(`${this.url}/authorization`, payload);
  }
}

export default new InstagramChannel();
