/* global axios */
import ApiClient from './ApiClient';

class FaqItemsAPI extends ApiClient {
  constructor() {
    super('faq_items', { accountScoped: true });
  }

  get({ page = 1, per_page = 50, q = undefined, category_id = undefined } = {}) {
    const params = { page, per_page };
    if (q) {
      params.q = q;
    }
    if (category_id) {
      params.category_id = category_id;
    }
    return axios.get(this.url, { params });
  }

  create(data) {
    return axios.post(this.url, { faq_item: data });
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, { faq_item: data });
  }

  toggleVisibility(id) {
    return axios.post(`${this.url}/${id}/toggle_visibility`);
  }

  bulkDelete(ids) {
    return axios.post(`${this.url}/bulk_delete`, { ids });
  }

  move(id, direction) {
    return axios.post(`${this.url}/${id}/move`, { direction });
  }
}

export default new FaqItemsAPI();
