/* global axios */
import ApiClient from '../ApiClient';

class ZaloChannel extends ApiClient {
  constructor() {
    super('channels/zalo_channel', { accountScoped: true });
  }

  create(params) {
    return axios.post(`${this.url}`, params);
  }

  secretKey() {
    return axios.get(`${this.url}/secret_key`);
  }

  reauthorizeZaloOa({ omniauthToken, inboxId }) {
    return axios.post(`${this.baseUrl()}/zalo/reauthorize_oa`, {
      omniauth_token: omniauthToken,
      inbox_id: inboxId,
    });
  }
}

export default new ZaloChannel();
