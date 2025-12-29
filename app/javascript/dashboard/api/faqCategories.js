/* global axios */
import ApiClient from './ApiClient';

class FaqCategoriesAPI extends ApiClient {
  constructor() {
    super('faq_categories', { accountScoped: true });
  }

  getTree({ page = 1, per_page = 50, q = undefined } = {}) {
    const params = { page, per_page };
    if (q) {
      params.q = q;
    }
    return axios.get(`${this.url}/tree`, { params });
  }

  create(data) {
    return axios.post(this.url, { faq_category: data });
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, { faq_category: data });
  }

  toggleVisibility(id) {
    return axios.post(`${this.url}/${id}/toggle_visibility`);
  }

  move(id, { parentId, position }) {
    return axios.post(`${this.url}/${id}/move`, {
      parent_id: parentId,
      position,
    });
  }
}

export default new FaqCategoriesAPI();
