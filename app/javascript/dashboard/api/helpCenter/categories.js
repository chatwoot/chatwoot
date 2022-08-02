/* global axios */

import PortalsAPI from './portals';

class CategoriesAPI extends PortalsAPI {
  get({ pageNumber, portalSlug, locale }) {
    return axios.get(
      `${this.url}/${portalSlug}/categories?page=${pageNumber}&locale=${locale}`
    );
  }

  create({ portalSlug, categoryObj }) {
    return axios.post(`${this.url}/${portalSlug}/categories`, categoryObj);
  }

  update({ portalSlug, categoryObj }) {
    return axios.patch(`${this.url}/${portalSlug}/categories`, categoryObj);
  }

  delete({ portalSlug, categoryId }) {
    return axios.delete(`${this.url}/${portalSlug}/categories/${categoryId}`);
  }
}

export default new CategoriesAPI();
