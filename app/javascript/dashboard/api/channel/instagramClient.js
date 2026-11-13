/* global axios */
import ApiClient from '../ApiClient';

class InstagramChannel extends ApiClient {
  constructor() {
    super('instagram', { accountScoped: true });
  }

  generateAuthorization(payload) {
    return axios.post(`${this.url}/authorization`, payload);
  }

  fetchAccounts(connectionToken) {
    return axios.post(`${this.url}/accounts`, {
      connection_token: connectionToken,
    });
  }

  connectAccount(connectionToken, instagramId) {
    return axios.post(`${this.url}/connections`, {
      connection_token: connectionToken,
      instagram_id: instagramId,
    });
  }
}

export default new InstagramChannel();
