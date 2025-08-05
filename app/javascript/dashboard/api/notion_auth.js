/* global axios */
import ApiClient from './ApiClient';

class NotionOAuthClient extends ApiClient {
  constructor() {
    super('notion', { accountScoped: true });
  }

  generateAuthorization() {
    return axios.post(`${this.url}/authorization`);
  }
}

export default new NotionOAuthClient();
