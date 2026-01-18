import ApiClient from './ApiClient';

class ProductsAPI extends ApiClient {
  constructor() {
    super('products', { accountScoped: true });
  }
}

export default new ProductsAPI();
