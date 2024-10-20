import types from '../../mutation-types';

export const mutations = {
  [types.SET_UI_FLAG](_state, uiFlags) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...uiFlags,
    };
  },

  [types.ADD_ARTICLE]: ($state, article) => {
    if (!article.id) return;

    $state.articles.byId[article.id] = article;
  },
  [types.CLEAR_ARTICLES]: $state => {
    $state.articles.allIds = [];
    $state.articles.byId = {};
    $state.articles.uiFlags.byId = {};
  },
  [types.ADD_MANY_ARTICLES]($state, articles) {
    const allArticles = { ...$state.articles.byId };
    articles.forEach(article => {
      allArticles[article.id] = article;
    });

    $state.articles.byId = allArticles;
  },
  [types.ADD_MANY_ARTICLES_ID]($state, articleIds) {
    $state.articles.allIds.push(...articleIds);
  },

  [types.SET_ARTICLES_META]: ($state, meta) => {
    $state.meta = meta;
  },

  [types.ADD_ARTICLE_ID]: ($state, articleId) => {
    if ($state.articles.allIds.includes(articleId)) return;
    $state.articles.allIds.push(articleId);
  },
  [types.UPDATE_ARTICLE_FLAG]: ($state, { articleId, uiFlags }) => {
    const flags = $state.articles.uiFlags.byId[articleId] || {};

    $state.articles.uiFlags.byId[articleId] = {
      ...{
        isFetching: false,
        isUpdating: false,
        isDeleting: false,
      },
      ...flags,
      ...uiFlags,
    };
  },
  [types.ADD_ARTICLE_FLAG]: ($state, { articleId, uiFlags }) => {
    $state.articles.uiFlags.byId[articleId] = {
      ...{
        isFetching: false,
        isUpdating: false,
        isDeleting: false,
      },
      ...uiFlags,
    };
  },
  [types.UPDATE_ARTICLE]: ($state, updatedArticle) => {
    const articleId = updatedArticle.id;
    if ($state.articles.byId[articleId]) {
      // Preserve the original position
      const originalPosition = $state.articles.byId[articleId].position;

      // Update the article, keeping the original position
      // This is not moved out of the original position when we update the article
      $state.articles.byId[articleId] = {
        ...updatedArticle,
        position: originalPosition,
      };
    }
  },
  [types.REMOVE_ARTICLE]($state, articleId) {
    const { [articleId]: toBeRemoved, ...newById } = $state.articles.byId;
    $state.articles.byId = newById;
  },
  [types.REMOVE_ARTICLE_ID]($state, articleId) {
    $state.articles.allIds = $state.articles.allIds.filter(
      id => id !== articleId
    );
  },
};
