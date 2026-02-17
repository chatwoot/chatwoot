/* global axios */
import ApiClient from '../ApiClient';

class XChannel extends ApiClient {
  constructor() {
    super('x', { accountScoped: true });
  }

  generateAuthorization(payload) {
    return axios.post(`${this.url}/authorization`, payload);
  }
}

export default new XChannel();
