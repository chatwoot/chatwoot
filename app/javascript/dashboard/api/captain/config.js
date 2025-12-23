/* global axios */
import ApiClient from '../ApiClient';

class CaptainConfig extends ApiClient {
  constructor() {
    super('captain/config', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }
}

export default new CaptainConfig();
