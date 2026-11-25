/* global axios */
import ApiClient from './ApiClient';

class CallsAPI extends ApiClient {
  constructor() {
    super('calls', { accountScoped: true });
  }

  get(params = {}) {
    return axios.get(this.url, { params });
  }
}

export default new CallsAPI();
