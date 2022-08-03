/* global axios */
import ApiClient from '../ApiClient';

class PortalsAPI extends ApiClient {
  constructor() {
    super('portals', { accountScoped: true });
  }

  getArticles({ pageNumber, portalSlug, locale, status, author_id }) {
    let baseUrl = `${this.url}/${portalSlug}/articles?page=${pageNumber}&locale=${locale}`;
    if (status !== undefined) baseUrl += `&status=${status}`;
    if (author_id) baseUrl += `&author_id=${author_id}`;
    return axios.get(baseUrl);
  }
}

export default new PortalsAPI();
