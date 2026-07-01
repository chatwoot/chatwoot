/* global axios */
import ApiClient from '../ApiClient';

class ZaloOaChannel extends ApiClient {
  constructor() {
    super('zalo_oa', { accountScoped: true });
  }

  generateAuthorization(payload) {
    return axios.post(`${this.url}/authorization`, payload);
  }
}

export default new ZaloOaChannel();
