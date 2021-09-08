/* global axios */
import ApiClient from './ApiClient';

class AttributeAPI extends ApiClient {
  constructor() {
    super('custom_attribute_definitions', { accountScoped: true });
  }

  getAttributesByModel(modelId) {
    return axios.get(`${this.url}?attribute_model=${modelId}`);
  }
}

export default new AttributeAPI();
