/* global axios */

import PortalsAPI from './portals';

class CategoriesAPI extends PortalsAPI {
  constructor() {
    super('categories', { accountScoped: true });
  }

  get({ portalSlug, locale }) {
    return axios.get(`${this.url}/${portalSlug}/categories?locale=${locale}`);
  }

  create({ portalSlug, categoryObj }) {
    return axios.post(`${this.url}/${portalSlug}/categories`, categoryObj);
  }

  update({ portalSlug, categoryId, categoryObj }) {
    return axios.patch(
      `${this.url}/${portalSlug}/categories/${categoryId}`,
      categoryObj
    );
  }

  delete({ portalSlug, categoryId }) {
    return axios.delete(`${this.url}/${portalSlug}/categories/${categoryId}`);
  }

  reorder({ portalSlug, reorderedGroup }) {
    return axios.post(`${this.url}/${portalSlug}/categories/reorder`, {
      positions_hash: reorderedGroup,
    });
  }
}

export default new CategoriesAPI();
