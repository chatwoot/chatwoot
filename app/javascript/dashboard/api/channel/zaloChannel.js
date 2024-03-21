/* global axios */
import ApiClient from '../ApiClient';

class ZaloChannel extends ApiClient {
  constructor() {
    super('zalo_indicators', { accountScoped: true });
  }

  create(params) {
    return axios.post(
      `${this.url.replace(this.resource, '')}channels/zalo_channel`,
      params
    );
  }

  reauthorizeZaloOa({ omniauthToken, inboxId }) {
    return axios.post(`${this.baseUrl()}/zalo/reauthorize_oa`, {
      omniauth_token: omniauthToken,
      inbox_id: inboxId,
    });
  }
}

export default new ZaloChannel();
