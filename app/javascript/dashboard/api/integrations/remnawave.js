/* global axios */

import ApiClient from '../ApiClient';

class RemnawaveAPI extends ApiClient {
  constructor() {
    super('integrations/remnawave', { accountScoped: true });
  }

  getUserInfo(contactId) {
    return axios.get(`${this.url}/user_info`, {
      params: { contact_id: contactId },
    });
  }

  enableUser(uuid) {
    return axios.post(`${this.url}/enable_user`, { uuid });
  }

  disableUser(uuid) {
    return axios.post(`${this.url}/disable_user`, { uuid });
  }

  resetTraffic(uuid) {
    return axios.post(`${this.url}/reset_traffic`, { uuid });
  }
}

export default new RemnawaveAPI();
