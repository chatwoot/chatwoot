/* global axios */
import ApiClient from './ApiClient';

class YearInReviewAPI extends ApiClient {
  constructor() {
    super('year_in_review', { accountScoped: true, apiVersion: 'v2' });
  }

  get(year) {
    return axios.get(`${this.url}`, {
      params: { year },
    });
  }
}

export default new YearInReviewAPI();
