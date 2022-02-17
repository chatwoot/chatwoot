/* global axios */
import ApiClient from './ApiClient';

class AttributeAPI extends ApiClient {
  constructor() {
    super('custom_attribute_definitions', { accountScoped: true });
  }

  getAttributesByModel() {
    return axios.get(this.url);
  }
}

export default new AttributeAPI();
