import ApiClient from './ApiClient';

class AttributeAPI extends ApiClient {
  constructor() {
    super('custom_attribute_definitions', { accountScoped: true });
  }
}

export default new AttributeAPI();
