/* global axios */
import ApiClient from '../ApiClient';

class CaptainTools extends ApiClient {
  constructor() {
    super('captain/assistants/tools', { accountScoped: true });
  }

  get({ signal, ...params } = {}) {
    return axios.get(this.url, {
      params,
      signal,
    });
  }
}

export default new CaptainTools();
