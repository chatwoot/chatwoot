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
    sort,
  }) {
    const queryParams = new URLSearchParams({ page: pageNumber, locale });

    if (status !== undefined) queryParams.set('status', status);
    if (author_id) queryParams.set('author_id', author_id);
    if (category_slug) queryParams.set('category_slug', category_slug);
    if (sort) queryParams.set('sort', sort);

    const baseUrl = `${
      this.url
    }/${portalSlug}/articles?${queryParams.toString()}`;
    return axios.get(baseUrl);
  }

  searchArticles({ portalSlug, query }) {
    return axios.get(`${this.url}/${portalSlug}/articles?query=${query}`);
  }

  getArticle({ id, portalSlug }) {
    return axios.get(`${this.url}/${portalSlug}/articles/${id}`);
  }

  updateArticle({ portalSlug, articleId, articleObj }) {
    return axios.patch(
      `${this.url}/${portalSlug}/articles/${articleId}`,
      articleObj
    );
  }

  createArticle({ portalSlug, articleObj }) {
    const { content, title, author_id, category_id } = articleObj;
    return axios.post(`${this.url}/${portalSlug}/articles`, {
      content,
      title,
      author_id,
      category_id,
    });
  }

  deleteArticle({ articleId, portalSlug }) {
    return axios.delete(`${this.url}/${portalSlug}/articles/${articleId}`);
  }

  reorderArticles({ portalSlug, reorderedGroup, categorySlug }) {
    return axios.post(`${this.url}/${portalSlug}/articles/reorder`, {
      positions_hash: reorderedGroup,
      category_slug: categorySlug,
    });
  }
}

export default new ArticlesAPI();
