/* global axios */
import ApiClient from '../ApiClient';

class ZaloOaChannel extends ApiClient {
  constructor() {
    super('zalo_oa', { accountScoped: true });
  }

  generateAuthorization(params) {
    return axios.post(`${this.baseUrl()}/zalo_oa/authorization`, params);
  }
}

export default new ZaloOaChannel();
