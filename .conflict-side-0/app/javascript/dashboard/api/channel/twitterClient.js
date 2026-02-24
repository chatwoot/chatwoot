/* global axios */
import ApiClient from '../ApiClient';

class TwitterClient extends ApiClient {
  constructor() {
    super('twitter', { accountScoped: true });
  }

  generateAuthorization() {
    return axios.post(`${this.url}/authorization`);
  }
}

export default new TwitterClient();
