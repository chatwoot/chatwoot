/* global axios */

import PortalsAPI from './portals';
import { getArticleSearchURL } from 'dashboard/helper/URLHelper.js';

class ArticlesAPI extends PortalsAPI {
  constructor() {
    super('articles', { accountScoped: true });
  }

  // eslint-disable-next-line class-methods-use-this
  getArticles({
    pageNumber,
    portalSlug,
    locale,
    status,
    author_id,
    category_slug,
    sort,
  }) {
    const url = getArticleSearchURL({
      pageNumber,
      portalSlug,
      locale,
      status,
      author_id,
      category_slug,
      sort,
    });

    return axios.get(url);
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
