import ApiClient from './ApiClient';

class CustomViewsAPI extends ApiClient {
  constructor() {
    super('custom_filters', { accountScoped: true });
  }

  getCustomViewsByFilterType(type) {
    return this.axios.get(`${this.url}?filter_type=${type}`);
  }

  deleteCustomViews(id, type) {
    return this.axios.delete(`${this.url}/${id}?filter_type=${type}`);
  }
}

export default new CustomViewsAPI();
