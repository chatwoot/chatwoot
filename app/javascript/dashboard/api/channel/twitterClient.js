import ApiClient from '../ApiClient';

class TwitterClient extends ApiClient {
  constructor() {
    super('twitter', { accountScoped: true });
  }

  generateAuthorization() {
    return this.axios.post(`${this.url}/authorization`);
  }
}

export default new TwitterClient();
