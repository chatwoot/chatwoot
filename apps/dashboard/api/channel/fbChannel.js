/* global axios */
import ApiClient from '../ApiClient';

class FBChannel extends ApiClient {
  constructor() {
    super('facebook_indicators', { accountScoped: true });
  }

  create(params) {
    return axios.post(
      `${this.url.replace(this.resource, '')}callbacks/register_facebook_page`,
      params
    );
  }

  reauthorizeFacebookPage({ omniauthToken, inboxId }) {
    return axios.post(`${this.baseUrl()}/callbacks/reauthorize_page`, {
      omniauth_token: omniauthToken,
      inbox_id: inboxId,
    });
  }
}

export default new FBChannel();
