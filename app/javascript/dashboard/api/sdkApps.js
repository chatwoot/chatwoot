/* global axios */
import ApiClient from './ApiClient';

class SdkAppsAPI extends ApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  show(inboxId) {
    return axios.get(`${this.url}/${inboxId}/sdk`);
  }

  update(inboxId, data) {
    return axios.patch(`${this.url}/${inboxId}/sdk`, data);
  }
}

export default new SdkAppsAPI();
