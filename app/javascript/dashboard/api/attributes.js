import CacheEnabledApiClient from './CacheEnabledApiClient';

class AttributeAPI extends CacheEnabledApiClient {
  constructor() {
    super('custom_attribute_definitions', { accountScoped: true });
  }

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    return 'custom_attribute_definition';
  }

  // eslint-disable-next-line class-methods-use-this
  extractDataFromResponse(response) {
    return response.data;
  }

  // eslint-disable-next-line class-methods-use-this
  marshallData(dataToParse) {
    return { data: dataToParse };
  }

  getAttributesByModel() {
    return super.get(true);
  }
}

export default new AttributeAPI();
