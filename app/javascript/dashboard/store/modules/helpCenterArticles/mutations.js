import types from '../../mutation-types';
import Vue from 'vue';

export const mutations = {
  [types.SET_UI_FLAG](_state, uiFlags) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...uiFlags,
    };
  },

  [types.ADD_ARTICLE]: ($state, article) => {
    if (!article.id) return;

    Vue.set($state.articles.byId, article.id, {
      ...article,
    });
  },
  [types.CLEAR_ARTICLES]: $state => {
    Vue.set($state.articles, 'byId', {});
    Vue.set($state.articles, 'allIds', []);
    Vue.set($state.articles, 'uiFlags.byId', {});
  },
  [types.ADD_MANY_ARTICLES]($state, articles) {
    const allArticles = { ...$state.articles.byId };
    articles.forEach(article => {
      allArticles[article.id] = article;
    });

    Vue.set($state.articles, 'byId', allArticles);
  },
  [types.ADD_MANY_ARTICLES_ID]($state, articleIds) {
    $state.articles.allIds.push(...articleIds);
  },

  [types.SET_ARTICLES_META]: ($state, data) => {
    const { articles_count: count, current_page: currentPage } = data;
    Vue.set($state.meta, 'count', count);
    Vue.set($state.meta, 'currentPage', currentPage);
  },

  [types.ADD_ARTICLE_ID]: ($state, articleId) => {
    if ($state.articles.allIds.includes(articleId)) return;
    $state.articles.allIds.push(articleId);
  },
  [types.UPDATE_ARTICLE_FLAG]: ($state, { articleId, uiFlags }) => {
    const flags =
      Object.keys($state.articles.uiFlags.byId).includes(articleId) || {};

    Vue.set($state.articles.uiFlags.byId, articleId, {
      ...{
        isFetching: false,
        isUpdating: false,
        isDeleting: false,
      },
      ...flags,
      ...uiFlags,
    });
  },
  [types.ADD_ARTICLE_FLAG]: ($state, { articleId, uiFlags }) => {
    Vue.set($state.articles.uiFlags.byId, articleId, {
      ...{
        isFetching: false,
        isUpdating: false,
        isDeleting: false,
      },
      ...uiFlags,
    });
  },
  [types.UPDATE_ARTICLE]($state, article) {
    const articleId = article.id;
    if (!$state.articles.allIds.includes(articleId)) return;

    Vue.set($state.articles.byId, articleId, {
      ...article,
    });
  },
  [types.REMOVE_ARTICLE]($state, articleId) {
    const { [articleId]: toBeRemoved, ...newById } = $state.articles.byId;
    Vue.set($state.articles, 'byId', newById);
  },
  [types.REMOVE_ARTICLE_ID]($state, articleId) {
    $state.articles.allIds = $state.articles.allIds.filter(
      id => id !== articleId
    );
  },
};
