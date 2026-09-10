/* global axios */
import ApiClient from './ApiClient';

class AttributeAPI extends ApiClient {
  constructor() {
    super('custom_attribute_definitions', { accountScoped: true });
  }

  getAttributesByModel() {
    return axios.get(this.url);
  }

  reorder(positionsHash) {
    return axios.post(`${this.url}/reorder`, { positions_hash: positionsHash });
  }
}

export default new AttributeAPI();
