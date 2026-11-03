/* global axios */
import ApiClient from './ApiClient';

class FilterRecommendationsApi extends ApiClient {
  constructor() {
    super('filter_recommendations', { accountScoped: true });
  }

  /**
   * @param {string} query - The description to build filters from
   * @param {'conversation'|'contact'} filterType - The records the filters apply to
   */
  create(query, filterType, { signal } = {}) {
    return axios.post(this.url, { query, filter_type: filterType }, { signal });
  }
}

export default new FilterRecommendationsApi();
