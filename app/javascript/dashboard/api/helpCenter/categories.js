import ApiClient from '../ApiClient';

class CategoriesAPI extends ApiClient {
  constructor() {
    super('categories', { accountScoped: true });
  }
}

export default new CategoriesAPI();
