export const getters = {
  uiFlags: state => helpCenterId => {
    const uiFlags = state.articles.uiFlags.byId[helpCenterId];
    if (uiFlags) return uiFlags;
    return { isFetching: false, isUpdating: false, isDeleting: false };
  },
  isFetching: state => state.uiFlags.isFetching,
  articleById: (...getterArguments) => articleId => {
    const [state] = getterArguments;
    const article = state.articles.byId[articleId];
    if (!article) return undefined;
    return article;
  },
  allArticles: (...getterArguments) => {
    const [state, _getters] = getterArguments;
    const articles = state.articles.allIds
      .map(id => {
        return _getters.articleById(id);
      })
      .filter(article => article !== undefined);
    return articles;
  },
  articleStatus: (...getterArguments) => articleId => {
    const [state] = getterArguments;
    const article = state.articles.byId[articleId];
    if (!article) return undefined;
    return article.status;
  },
  getMeta: state => {
    return state.meta;
  },
};
