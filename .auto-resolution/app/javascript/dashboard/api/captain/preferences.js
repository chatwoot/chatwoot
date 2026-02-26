/* global axios */
import ApiClient from '../ApiClient';

class CaptainPreferences extends ApiClient {
  constructor() {
    super('captain/preferences', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  updatePreferences(data) {
    return axios.put(this.url, data);
  }
}

export default new CaptainPreferences();
