/* global axios */

import PortalsAPI from './portals';

class ArticlesAPI extends PortalsAPI {
  constructor() {
    super('articles', { accountScoped: true });
  }

  getArticles({
    pageNumber,
    portalSlug,
    locale,
    status,
    author_id,
    category_slug,
  }) {
    let baseUrl = `${this.url}/${portalSlug}/articles?page=${pageNumber}&locale=${locale}`;
    if (status !== undefined) baseUrl += `&status=${status}`;
    if (author_id) baseUrl += `&author_id=${author_id}`;
    if (category_slug) baseUrl += `&category_slug=${category_slug}`;
    return axios.get(baseUrl);
  }
}

export default new ArticlesAPI();
