/* global axios */
import ApiClient from './ApiClient';

class FilterRecommendationsApi extends ApiClient {
  constructor() {
    super('filter_recommendations', { accountScoped: true });
  }

  /**
   * @param {Object} request
   * @param {string} request.query - The description to build filters from
   * @param {'conversation'|'contact'|'automation'} request.filterType - What the filters apply to
   * @param {string[]} [request.attributeKeys] - For automations, the condition keys the rule's event offers
   */
  create({ query, filterType, attributeKeys }, { signal } = {}) {
    return axios.post(
      this.url,
      { query, filter_type: filterType, attribute_keys: attributeKeys },
      { signal }
    );
  }
}

export default new FilterRecommendationsApi();
