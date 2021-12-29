/* global axios */
import ApiClient from './ApiClient';

class CustomViewsAPI extends ApiClient {
  constructor() {
    super('custom_filters', { accountScoped: true });
  }

  getCustomViews() {
    return axios.get(this.url);
  }
}

export default new CustomViewsAPI();
