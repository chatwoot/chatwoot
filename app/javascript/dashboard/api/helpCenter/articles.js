import ApiClient from '../ApiClient';

class ArticlesAPI extends ApiClient {
  constructor() {
    super('articles', { accountScoped: true });
  }
}

export default new ArticlesAPI();
