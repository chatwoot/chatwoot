/* global axios */
import ApiClient from '../ApiClient';

class WootQL extends ApiClient {
  constructor() {
    super('captain/wootql', { accountScoped: true });
  }

  run(source, offset, config) {
    return axios.post(this.url, { source, offset }, config);
  }

  resources(config) {
    return axios.get(this.url, config);
  }
}

export default new WootQL();
