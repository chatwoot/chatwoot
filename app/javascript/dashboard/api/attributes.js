/* global axios */
import ApiClient from './ApiClient';

class AttributeAPI extends ApiClient {
  constructor() {
    super('custom_attribute_definitions', { accountScoped: true });
  }

  getAttributesByModel() {
    return axios.get(this.url);
  }

  recalculate(id) {
    return axios.post(`${this.url}/${id}/recalculate`);
  }

  preview(id, sampleAttributes) {
    return axios.post(`${this.url}/${id}/preview`, {
      sample_attributes: sampleAttributes,
    });
  }
}

export default new AttributeAPI();
