/* global axios */
import ApiClient from '../ApiClient';

class PortalsAPI extends ApiClient {
  constructor() {
    super('portals', { accountScoped: true });
  }

  getArticles({ pageNumber, portalSlug, locale }) {
    return axios.get(
      `${this.url}/${portalSlug}/articles?page=${pageNumber}&locale=${locale}`
    );
  }
}

export default new PortalsAPI();
