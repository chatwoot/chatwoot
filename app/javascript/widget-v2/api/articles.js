import axios from 'axios';

// Public help-center JSON API; served same-origin, no widget auth involved.
export const fetchArticles = ({ slug, locale, query, sort, page = 1 }) =>
  axios
    .get(`/hc/${slug}/${locale}/articles.json`, {
      params: { query: query || undefined, sort, page, status: 1 },
    })
    .then(response => response.data);

export const fetchArticle = ({ slug, articleSlug }) =>
  axios
    .get(`/hc/${slug}/articles/${articleSlug}.json`)
    .then(response => response.data);
