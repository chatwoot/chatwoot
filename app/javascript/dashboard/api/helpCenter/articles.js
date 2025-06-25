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

  uploadImage({ portalSlug, file }) {
    let formData = new FormData();
    formData.append('background_image', file);
    return axios.post(
      `${this.url}/${portalSlug}/articles/attach_file`,
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    );
  }

  reorderArticles({ portalSlug, reorderedGroup, categorySlug }) {
    return axios.post(`${this.url}/${portalSlug}/articles/reorder`, {
      positions_hash: reorderedGroup,
      category_slug: categorySlug,
    });
  }
}

export default new ArticlesAPI();
