/* global axios */
import ApiClient from './ApiClient';

class AttributeAPI extends ApiClient {
  constructor() {
    super('custom_attribute_definitions', { accountScoped: true });
  }

  getAttributesByModel() {
    return axios.get(this.url);
  }

  getDataSourceValues() {
    return axios.get(`${this.url}/data_source_values`);
  }
}

export default new AttributeAPI();
