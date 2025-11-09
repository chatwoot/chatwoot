/* global axios */
import ApiClient from './ApiClient';

class ProductMediaAPI extends ApiClient {
  constructor() {
    super('product_catalogs', { accountScoped: true });
  }

  setPrimary(productCatalogId, mediaId) {
    return axios.post(
      `${this.url}/${productCatalogId}/product_media/${mediaId}/set_primary`
    );
  }
}

export default new ProductMediaAPI();
