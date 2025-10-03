/* global axios */
import ApiClient from '../ApiClient';

class CaptainTools extends ApiClient {
  constructor() {
    super('captain/assistant/tools', { accountScoped: true });
  }

  get(params = {}) {
    return axios.get(this.url, {
      params,
    });
  }
}

export default new CaptainTools();
