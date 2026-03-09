import axios from 'axios';

class ArticlesAPI {
  constructor() {
    this.baseUrl = '';
  }

  searchArticles(portalSlug, locale, query) {
    let baseUrl = `${this.baseUrl}/hc/${portalSlug}/${locale}/articles.json?query=${query}`;
    return axios.get(baseUrl);
  }
}

export default new ArticlesAPI();
