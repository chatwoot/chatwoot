/* global axios */
import ApiClient from '../ApiClient';

class MicrosoftClient extends ApiClient {
  constructor() {
    super('microsoft', { accountScoped: true });
  }

  generateAuthorization() {
    return axios.post(`${this.url}/authorization`);
  }
}

export default new MicrosoftClient();
