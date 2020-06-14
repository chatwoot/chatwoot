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
}

export default new FBChannel();
